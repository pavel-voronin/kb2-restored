"""Acquire the body ritual, combine two donors, then use the new creature."""

from state import state, summary
from solve import ensure_wizard, portal
from objectives import ritual
from detour import refill, field_battle
from config import WORK


def workshop(p):
    while state(p.vm).Campaign.MagicPower < 40:
        ensure_wizard(p, 2)
    if not state(p.vm).Campaign.Flags.SpellAvailable[0]:
        root = p.checkpoint()
        for k in range(256):
            p.rewind(root)
            p.send(18, idle_polls=402 * k)
            p.settle()
            if state(p.vm).Campaign.HiddenSpellEffect == 0:
                break
        else:
            raise RuntimeError("Could not find body ritual placement")
        p.save(WORK / "SEARCH/body-placement.json")
        ritual(p)
    p.save(WORK / "SEARCH/body-acquired.json")
    ensure_wizard(p, 4)
    p.settle()
    g = state(p.vm).Campaign
    if not g.Flags.SpellUsed[0]:
        raise RuntimeError("Ritual book was not read")
    refill(p, 8)
    g = state(p.vm).Campaign
    island = g.RitualStoneIsland
    stone = g.RitualStonePosition.X, g.RitualStonePosition.Y
    stand = stone[0], stone[1] + 1
    portal(p, island, stand)
    if not p.goto(stand, safe=True):
        raise RuntimeError("Ritual stone entrance unreachable")
    p.send(72)
    print("WORKSHOP", p.vm.text[-18:], flush=True)
    p.send(28)
    p.send(28)
    p.send(80)
    p.send(28)
    p.send(72)
    p.send(28)
    p.send(1)
    if not any(25 <= a.Species <= 29 for a in state(p.vm).Campaign.Army):
        raise RuntimeError(("Mutant not created", p.vm.text[-20:]))
    p.send(31)
    p.settle()
    print("MUTANT CREATED", summary(p.vm), flush=True)
    p.notes.append("objective:workshop")
    p.save(WORK / "SEARCH/mutant-created.json")
    field_battle(p)
