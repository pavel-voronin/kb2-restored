"""Construct a complete hardest-difficulty keyboard witness, then diversify it."""

import argparse
from play import Play
from config import WORK
from state import state, summary


def ensure_wizard(p, option=None, **kwargs):
    visited = set()
    for attempt in range(12):
        g = state(p.vm).Campaign
        x, y = g.Hero.X, g.Hero.Y
        if not any(
            g.Map[g.Island - 1][x + dx][y + dy] == 0
            for dx in (-1, 0, 1)
            for dy in (-1, 0, 1)
            if dx or dy
        ):
            candidates = []
            for xx, yy in p.component():
                if any(
                    g.Map[g.Island - 1][xx + dx][yy + dy] == 0
                    for dx in (-1, 0, 1)
                    for dy in (-1, 0, 1)
                    if dx or dy
                ):
                    route = p.path((xx, yy))
                    if route:
                        candidates.append((len(route), (xx, yy)))
            if candidates:
                p.clear_nearby()
                p.goto(min(candidates)[1])
                p.settle()
            else:
                p.clear_nearby()
                for dx, dy, key in __import__("play").DIRECTIONS:
                    if dx and dy:
                        continue
                    tile = g.Map[g.Island - 1][x + dx][y + dy]
                    if 64 <= tile < 80 and g.Woodcutters:
                        p.work(2, key)
                        break
                    if 80 <= tile < 96 and g.Stonecutters:
                        p.work(4, key)
                        break
                    if 48 <= tile < 64 and g.Carpenters:
                        p.work(1, key)
                        p.send(key)
                        p.settle()
                        break
        if p.wizard_timed(option, **kwargs):
            return True
        g = state(p.vm).Campaign
        x, y = g.Hero.X, g.Hero.Y
        visited.add((x, y))
        if g.TornadoCharges:
            p.clear_nearby()
        moved = False
        for dx, dy, key in __import__("play").DIRECTIONS:
            xy = x + dx, y + dy
            if xy in visited or not (2 <= xy[0] <= 63 and 2 <= xy[1] <= 63):
                continue
            tile = state(p.vm).Campaign.Map[g.Island - 1][xy[0]][xy[1]]
            if tile in (0, 4) or 32 <= tile < 48:
                p.send(key)
                p.settle()
                moved = True
                break
        if not moved:
            p.send(47)
            p.settle()
    raise RuntimeError(("Could not reach a matching wizard", summary(p.vm)))


def bank(p, amount):
    while state(p.vm).Campaign.Gold < amount:
        if state(p.vm).Campaign.Weeks < 10:
            raise RuntimeError("Insufficient time budget for income")
        p.wait_week()
    print("BANK", summary(p.vm), "income", state(p.vm).Campaign.Income, flush=True)


def portal(p, island, target=None, connected=False):
    while state(p.vm).Campaign.WizardRelations[state(p.vm).Campaign.Island - 1] < 2:
        ensure_wizard(p)
    if state(p.vm).Campaign.Gold > 20000:
        while state(p.vm).Campaign.WizardRelations[state(p.vm).Campaign.Island - 1] < 4:
            ensure_wizard(p)
        while state(p.vm).Campaign.TornadoCharges < 3:
            ensure_wizard(p, 5)
    for job, field in ((1, "Carpenters"), (2, "Woodcutters"), (4, "Stonecutters")):
        while getattr(state(p.vm).Campaign, field) < 4:
            ensure_wizard(p, 1)
            p.char(str(job))
            p.settle()
    bank(p, 5000)
    return ensure_wizard(
        p, 3, travel=island, landing_target=target, landing_connected=connected
    )


def finish(p, voyage=False):
    def ending():
        p.send(49)
        if voyage:
            from recovery import sea_landing

            sea_landing(p)
        p.char("6")
        if p.vm.pending["kind"] != "victory":
            raise RuntimeError("Final ending absent")
        p.notes.append(
            "Reached FirstSeriesEnding on hardest difficulty with five map parts."
        )
        p.events.append({"scan": 28, "at": "victory"})
        p.vm.run(28)
        if p.vm.pending["kind"] == "key":
            p.events.append({"scan": 28, "at": "key"})
            p.vm.run(28)
        if p.vm.pending != {"kind": "exit", "code": 0}:
            raise RuntimeError(("Ending did not exit", p.vm.pending))
        print("COMPLETE VICTORY", summary(p.vm), p.vm.pending, flush=True)

    g = state(p.vm).Campaign
    if g.MapParts < 5:
        raise RuntimeError("Five map parts required")
    if g.Flags.ShipOwned:
        if g.ShipIsland != g.Island:
            portal(p, g.ShipIsland, (g.Ship.X, g.Ship.Y))
        g = state(p.vm).Campaign
        if not state(p.vm).Runtime.ShipAbandonBlocked:
            if not p.goto((g.Ship.X, g.Ship.Y), safe=True):
                raise RuntimeError("Owned ship unreachable")
            p.settle()
        if state(p.vm).Runtime.ShipAbandonBlocked:
            ending()
            return
        raise RuntimeError("Could not board owned ship")
    candidates = []
    for island in range(1, 6):
        for town in g.Towns[island - 1]:
            if not (3 <= town.X <= 63 and 3 <= town.Y <= 63):
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    xy = town.X + dx, town.Y + dy
                    if g.Map[island - 1][xy[0]][xy[1]] == 0:
                        candidates.append((island, (town.X, town.Y), xy))
                        break
                else:
                    continue
                break
    if not candidates:
        raise RuntimeError("No town landing")
    for island, town, landing in candidates:
        snap = p.checkpoint()
        try:
            portal(p, island, landing)
            p.clear_nearby()
            if not p.goto(town):
                raise RuntimeError("Town unreachable")
            print("TOWN", town, p.vm.dialog, flush=True)
            p.char("2")
            p.settle()
            g = state(p.vm).Campaign
            if not g.Flags.ShipOwned:
                raise RuntimeError("Ship purchase failed")
            ship = (g.Ship.X, g.Ship.Y)
            p.clear_nearby()
            if not p.goto(ship):
                raise RuntimeError("Ship unreachable")
            p.settle()
            if not state(p.vm).Runtime.ShipAbandonBlocked:
                raise RuntimeError("Not on board")
            ending()
            return
        except RuntimeError as e:
            print("Retry town", island, town, str(e)[:220], flush=True)
            p.rewind(snap)
    raise RuntimeError("No reachable ship town")


def solve(seed=1, variant="CUR", resume=None, scenario="economic", finish_game=True):
    p = Play.resume(resume) if resume else Play(seed, variant)
    dest = WORK / "SEARCH" / f"solve-{seed}-{variant}-{scenario}.json"
    try:
        if not resume:
            p.collect(1600)
        if not resume:
            bank(p, 25000)
            while state(p.vm).Campaign.WizardRelations[0] < 1:
                ensure_wizard(p)
            while state(p.vm).Campaign.MagicPower < 3:
                ensure_wizard(p, 2)
            for job in (1, 2, 4):
                ensure_wizard(p, 1)
                p.char(str(job))
                p.settle()
            bank(p, 160000 if scenario == "quest" else 100000)
        for island in range(1, 6):
            for scroll in range(2):
                g = state(p.vm).Campaign
                targets = [
                    (x, y)
                    for x in range(3, 64)
                    for y in range(3, 64)
                    if g.Map[island - 1][x][y] == 9
                ]
                if not targets:
                    break
                target = (
                    min(targets, key=lambda xy: len(p.path(xy) or []) or 99999)
                    if g.Island == island
                    else targets[0]
                )
                if g.Island != island or not p.path(target):
                    portal(p, island, target)
                wanted = (
                    "clear-quest"
                    if scenario == "quest" and not any(q == 0 for q in g.QuestFlags)
                    else "double-gold"
                )
                if not p.paper(target, wanted):
                    portal(p, island, target)
                    assert p.paper(target, wanted), (
                        "Scroll unreachable",
                        island,
                        target,
                    )
                p.save(dest)
                print("SCROLL", island, scroll, summary(p.vm), flush=True)
        print("ALL SCROLLS", summary(p.vm), flush=True)
        if scenario == "quest":
            from quest import king_reward

            king_reward(p)
            p.save(dest)
        for island in range(1, 6):
            if state(p.vm).Campaign.WizardVisited[island - 1] & 2:
                continue
            if state(p.vm).Campaign.Island != island:
                portal(p, island)
            while state(p.vm).Campaign.WizardRelations[island - 1] < 5:
                ensure_wizard(p)
            bank(p, 500000)
            ensure_wizard(p, 6, offer="($500000)")
            p.settle()
            p.save(dest)
            print("MAP", island, summary(p.vm), flush=True)
        if finish_game:
            finish(p)
        return p
    finally:
        p.save(dest)


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("--seed", type=int, default=1)
    a.add_argument("--variant", default="CUR")
    a.add_argument("--resume")
    a.add_argument("--scenario", choices=("economic", "quest"), default="economic")
    args = a.parse_args()
    p = solve(args.seed, args.variant, args.resume, args.scenario)
    print("FINISH STATE", summary(p.vm), flush=True)
