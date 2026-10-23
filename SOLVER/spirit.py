"""Find the spirit ritual and summon it with purchased pearls."""

from config import WORK
from state import state, summary
from objectives import visit, ritual


def spirit(p):
    for _ in range(8):
        if state(p.vm).Campaign.Flags.SpellAvailable[7]:
            break
        if state(p.vm).Campaign.HiddenSpellIsland != 100:
            ritual(p)
            p.save(WORK / "SEARCH/spirit-learned.json")
            continue
        root = p.checkpoint()
        for k in range(256):
            p.rewind(root)
            p.send(18, idle_polls=402 * k)
            p.settle()
            if state(p.vm).Campaign.HiddenSpellEffect == 7:
                break
        else:
            raise RuntimeError("Spirit ritual placement not found")
        p.save(WORK / "SEARCH/spirit-placement.json")
        ritual(p)
        p.save(WORK / "SEARCH/spirit-learned.json")
    for island in (2, 3, 4, 5):
        if state(p.vm).Campaign.Relics[island - 2].Owned:
            continue
        t = state(p.vm).Campaign.Towns[island - 1][0]
        visit(p, island, (t.X, t.Y))
        p.char("8")
        p.send(28)
        p.send(1)
        if not state(p.vm).Campaign.Relics[island - 2].Owned:
            raise RuntimeError("Relic not acquired")
        p.save(WORK / "SEARCH/spirit-relics.json")
    p.notes.append("effect:relics")
    for island in (5, 4, 3, 2, 1):
        for slot in range(5):
            need = 100 - state(p.vm).Campaign.Cargo[6]
            if need <= 0:
                break
            t = state(p.vm).Campaign.Towns[island - 1][slot]
            visit(p, island, (t.X, t.Y))
            p.char("7")
            stock = state(p.vm).Runtime.GoodsStock[6]
            if stock:
                p.char("7")
                p.enter_number(min(need, stock))
            p.send(1)
            p.send(1)
            p.save(WORK / "SEARCH/spirit-pearls.json")
        if state(p.vm).Campaign.Cargo[6] >= 100:
            break
    if state(p.vm).Campaign.Cargo[6] < 100:
        raise RuntimeError("Pearl markets exhausted")
    stone = state(p.vm).Runtime.SpiritStonePosition
    pos = stone.X, stone.Y
    visit(p, 5, pos)
    p.settle()
    g = state(p.vm).Campaign
    if g.Cargo[6] != 0 or (
        g.RitualStoneIsland,
        g.RitualStonePosition.X,
        g.RitualStonePosition.Y,
    ) != (5, *pos):
        raise RuntimeError("Spirit was not summoned")
    p.notes.append("effect:spirit")
    p.save(WORK / "SEARCH/spirit-summoned.json")
    print("SPIRIT SUMMONED", summary(p.vm), flush=True)
