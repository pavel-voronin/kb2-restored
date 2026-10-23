"""Coverage-directed legal-input objectives, composed before the same ending."""

import argparse, json
from pathlib import Path
from play import Play
from config import WORK
from state import state, summary, creatures
from solve import portal, finish
from detour import walk, refill
from tactics import fight, aim


def visit(p, island, target):
    if state(p.vm).Campaign.Island != island or not p.path(target):
        portal(p, island, target)
    if not walk(p, target):
        portal(p, island, target)
        if not walk(p, target):
            raise RuntimeError(("Cannot approach", island, target))
    p.send(p.path(target)[0][0])


def menus(p):
    for key in (24, 48, 23, 19, 30, 34, 50, 31):
        p.send(key)
        p.settle()
    print("MENUS/SAVE", summary(p.vm), flush=True)


def town(p):
    t = state(p.vm).Campaign.Towns[0][0]
    visit(p, 1, (t.X, t.Y))
    p.char("1")
    p.send(21)
    p.send(28)
    p.char("5")
    p.char("6")
    p.char("3")
    p.enter_number(1)
    p.send(1)
    p.char("7")
    stock = state(p.vm).Runtime.GoodsStock
    product = next(i + 1 for i, n in enumerate(stock) if n)
    p.char(str(product))
    p.enter_number(1)
    p.send(15)
    p.char(str(product))
    p.enter_number(1)
    p.send(1)
    p.char("4")
    p.send(28)
    p.send(1)
    print(
        "TOWN OBJECTIVES",
        summary(p.vm),
        "scrolls",
        list(state(p.vm).Campaign.Scrolls),
        flush=True,
    )


def cave(p):
    g = state(p.vm).Campaign
    u = g.Underground[0][0]
    visit(p, 1, (u.X, u.Y))
    p.settle()
    print("UNDERGROUND", summary(p.vm), flush=True)


def castle(p):
    g = state(p.vm).Campaign
    defs = creatures(p.vm)
    choices = [
        (
            sum(
                defs[s].Defense * n
                for s, n in zip(
                    g.Castles[q.Island - 1][q.Slot - 1].Species,
                    g.Castles[q.Island - 1][q.Slot - 1].Counts,
                )
                if s < 100
            ),
            i + 1,
        )
        for i, q in enumerate(g.Contracts[0])
        if q.Island <= 5 and q.Slot > 1
    ]
    wanted = min(choices)[1]
    if g.ContractIsland != 1 or g.ContractSlot != wanted:
        t = g.Towns[0][0]
        visit(p, 1, (t.X, t.Y))
        for _ in range(6):
            p.char("1")
            if state(p.vm).Runtime.CurrentContractOffer == wanted:
                p.send(21)
                p.send(28)
                break
            p.send(49)
        p.send(1)
    g = state(p.vm).Campaign
    ci, cs = g.ContractIsland, g.ContractSlot
    contract = g.Contracts[ci - 1][cs - 1]
    island, slot = contract.Island, contract.Slot
    c = g.Castles[island - 1][slot - 1]
    target = c.X, c.Y
    # Castles are entered from the south.
    positions = [
        (c.X + dx, c.Y + dy)
        for dy in (1, 0)
        for dx in (-1, 0, 1)
        if (dx or dy)
        and (
            g.Map[island - 1][c.X + dx][c.Y + dy] in (0, 4)
            or 32 <= g.Map[island - 1][c.X + dx][c.Y + dy] < 48
        )
    ]
    if not positions:
        raise RuntimeError("No south entrance")
    from planning import component_labels

    labels, sizes, _ = component_labels(bytes(g.Map[island - 1]))
    landing = max(positions, key=lambda xy: sizes.get(labels.get(xy), 0))
    portal(p, island, landing, connected=True)
    p.clear_nearby()
    if not p.goto(landing):
        raise RuntimeError("Cannot stand south of castle")
    p.settle()
    p.clear_nearby()
    root = p.checkpoint()
    best = None
    for k in range(64):
        p.rewind(root)
        try:
            p.send(aim(landing, target), idle_polls=402 * k)
            if p.vm.pending["kind"] != "key":
                continue
            if slot == 1 and state(p.vm).Campaign.QuestFlags[island - 1] < 10:
                p.char("3")
                p.settle()
                p.send(aim(landing, target))
            p.send(21)
            fight(p)
            if state(p.vm).Campaign.Castles[island - 1][slot - 1].Owned:
                score = sum(
                    creatures(p.vm)[a.Species].Defense * a.Count
                    for a in state(p.vm).Campaign.Army
                    if a.Species < 100
                )
                if best is None or score > best[0]:
                    best = (score, p.vm.snapshot(), p.events.copy(), k)
        except RuntimeError:
            continue
    if best is None:
        p.rewind(root)
        raise RuntimeError("Castle capture failed in timing search")
    p.vm.restore(best[1])
    p.events = best[2]
    p.notes.append("castle timing polls=" + str(402 * best[3]))
    print("CASTLE CAPTURED", summary(p.vm), flush=True)
    p.send(aim(landing, target))
    p.char("1")
    p.char("1")
    p.send(1)
    p.settle()
    if not any(a.Species < 100 for a in state(p.vm).Campaign.Army):
        raise RuntimeError("Garrison retrieval failed")


def ritual(p):
    from detour import recruit

    for species in (20, 23, 17, 18, 22):
        recruit(p, species)
    p.save(WORK / "SEARCH/ritual-army.json")
    refill(p, 8)
    g = state(p.vm).Campaign
    island = g.HiddenSpellIsland
    pos = g.HiddenSpellPosition.X, g.HiddenSpellPosition.Y
    print("HIDDEN", island, pos, "effect", g.HiddenSpellEffect, flush=True)
    portal(p, island, pos)
    if not p.goto(pos, safe=True):
        raise RuntimeError("Hidden spell position unreachable")
    p.settle()
    p.clear_nearby()
    root = p.checkpoint()
    best = None
    for k in range(256):
        p.rewind(root)
        p.send(46, idle_polls=402 * k)
        candidate = state(p.vm).Campaign
        defs = creatures(p.vm)
        if candidate.Map[island - 1][pos[0]][pos[1]] != 23:
            continue
        score = sum(
            defs[s].Attack * n * (1.5 if defs[s].Flags & 31 else 1)
            + (10000 if s in (17, 23, 24) else 0)
            for s, n in zip(candidate.GuardianSpecies, candidate.GuardianCounts)
            if s < 100
        )
        if best is None or score < best[0]:
            best = (score, p.vm.snapshot(), p.events.copy())
    if best is None:
        raise RuntimeError("Hidden position was not reached")
    p.vm.restore(best[1])
    p.events = best[2]
    print(
        "GUARDIANS",
        best[0],
        list(state(p.vm).Campaign.GuardianSpecies),
        list(state(p.vm).Campaign.GuardianCounts),
        flush=True,
    )
    p.settle()
    visit(p, island, pos)
    p.send(21)
    fight(p)
    if not state(p.vm).Campaign.Flags.SpellAvailable[g.HiddenSpellEffect]:
        raise RuntimeError("Ritual spell not acquired")
    print(
        "RITUAL WON",
        summary(p.vm),
        list(state(p.vm).Campaign.Flags.SpellAvailable),
        flush=True,
    )


def run(path, only=None):
    w = json.loads(Path(path).read_text(encoding="utf-8"))
    p = Play.resume(path)
    if p.vm.pending["kind"] != "step":
        raise RuntimeError(("Prefix is not at an adventure checkpoint", p.vm.pending))
    if "objective:cave" in p.notes and summary(p.vm) != w["summary"]:
        raise RuntimeError(("Prefix summary differs", summary(p.vm), w["summary"]))
    dest = WORK / "SEARCH/objectives-progress.json"
    for name, fn in (
        ("menus", menus),
        ("town", town),
        ("cave", cave),
        ("castle", castle),
        ("ritual", ritual),
    ):
        if "objective:" + name in p.notes:
            continue
        if only and name not in only:
            continue
        snap = p.checkpoint()
        try:
            fn(p)
        except Exception:
            p.rewind(snap)
            p.save(dest)
            raise
        p.notes.append("objective:" + name)
        p.save(dest)
    finish(p)
    p.save(WORK / "SEARCH/objectives-win.json")
    return p


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("prefix")
    a.add_argument("--only", nargs="+")
    args = a.parse_args()
    run(args.prefix, args.only)
