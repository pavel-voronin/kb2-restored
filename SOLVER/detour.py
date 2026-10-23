"""Extend a winning campaign with mechanic-directed side trips, then finish."""

import argparse
from play import Play
from config import WORK
from state import state, summary, creatures
from solve import ensure_wizard, portal, finish


def refill(p, n=3):
    while state(p.vm).Campaign.WizardRelations[state(p.vm).Campaign.Island - 1] < 4:
        ensure_wizard(p)
    while state(p.vm).Campaign.TornadoCharges < n:
        ensure_wizard(p, 5)


def walk(p, target, limit=600):
    for _ in range(limit):
        if state(p.vm).Campaign.TornadoCharges < 1:
            refill(p)
        p.clear_nearby()
        path = p.path(target)
        if not path:
            work = p.work_path(target)
            if not work:
                return False
            key, pos, job = work[0]
            if job:
                p.work(job, key)
                continue
            p.send(key)
            p.settle()
            continue
        if len(path) == 1:
            return True
        p.send(path[0][0])
        p.settle()
    return False


def leadership(p, goal=1500):
    for number in range(40):
        g = state(p.vm).Campaign
        if g.Leadership >= goal:
            return
        targets = [
            (x, y) for x in range(3, 64) for y in range(3, 64) if g.Map[4][x][y] == 10
        ]
        paths = [(len(path), target) for target in targets if (path := p.path(target))]
        if not paths:
            if not targets:
                raise RuntimeError("All desert treasures exhausted")
            portal(p, 5, targets[0])
            continue
        target = min(paths)[1]
        if not walk(p, target):
            continue
        key = p.path(target)[0][0]
        root = p.checkpoint()
        for k in range(200):
            p.rewind(root)
            p.send(key, idle_polls=402 * k)
            if any("Раздать воинам" in x for x in p.vm.dialog):
                p.char("2")
                p.settle()
                break
        else:
            raise RuntimeError("No leadership treasure outcome")
        print("LEADERSHIP", number, summary(p.vm), flush=True)
        p.save(WORK / "SEARCH/detour-progress.json")
    raise RuntimeError("Leadership target not attained")


def recruit(p, species):
    g = state(p.vm).Campaign
    existing = sum(a.Count for a in g.Army if a.Species == species)
    capacity = (g.Leadership + g.LeadershipBonus) // creatures(p.vm)[species].Defense
    if existing >= capacity:
        return
    choices = [
        (island + 1, d.X, d.Y, d.Count)
        for island in range(5)
        for d in g.Dwellings[island]
        if d.Species == species and d.Count
    ]
    if not choices:
        raise RuntimeError(("No dwelling species", species))
    for island, x, y, count in choices:
        snap = p.checkpoint()
        try:
            portal(p, island, (x, y))
            if not walk(p, (x, y)):
                raise RuntimeError("No dwelling approach")
            p.send(p.path((x, y))[0][0])
            limit = min(
                count,
                (state(p.vm).Campaign.Leadership + state(p.vm).Campaign.LeadershipBonus)
                // creatures(p.vm)[species].Defense
                - existing,
            )
            if not limit:
                raise RuntimeError("Insufficient leadership")
            p.enter_number(limit)
            p.settle()
            if (
                sum(a.Count for a in state(p.vm).Campaign.Army if a.Species == species)
                != existing + limit
            ):
                raise RuntimeError("Recruitment failed")
            print("RECRUIT", species, summary(p.vm), flush=True)
            return
        except RuntimeError as e:
            print("Retry dwelling", island, x, y, str(e)[:150], flush=True)
            p.rewind(snap)
    raise RuntimeError(("All dwellings failed", species))


def field_battle(p):
    from tactics import fight

    portal(p, 1)
    for _ in range(1000):
        g = state(p.vm).Campaign
        paths = [
            (len(path), (x, y))
            for x in range(3, 64)
            for y in range(3, 64)
            if g.Map[0][x][y] == 5 and (path := p.path((x, y)))
        ]
        if not paths:
            armies = [
                a
                for a in g.WanderingArmies[0]
                if 3 <= a.X <= 63 and 3 <= a.Y <= 63 and g.Map[0][a.X][a.Y] == 5
            ]
            if not armies:
                raise RuntimeError("No wandering enemies remain")
            enemy = min(armies, key=lambda a: sum(a.Counts))
            portal(p, 1, (enemy.X, enemy.Y))
            continue
        target = min(paths)[1]
        path = p.path(target)
        p.send(path[0][0])
        if p.vm.pending["kind"] == "key":
            if "Дpаться будешь" in " ".join(p.vm.dialog):
                p.send(21)
                fight(p)
                if state(p.vm).Runtime.BattleResult != 1:
                    raise RuntimeError("Field battle not won")
                return
            p.settle()
    raise RuntimeError("Field battle approach exhausted")


def rich(path, stage="army"):
    p = Play.resume(path)
    dest = WORK / "SEARCH/detour-progress.json"
    try:
        if stage == "army":
            leadership(p)
        while state(p.vm).Campaign.MagicPower < 22:
            ensure_wizard(p, 2)
        g = state(p.vm).Campaign
        print(
            "DWELLINGS",
            [(i, d.X, d.Y, d.Species, d.Count) for i, d in enumerate(g.Dwellings[4])],
            flush=True,
        )
        p.save(dest)
        if stage == "combat":
            for species in (20, 23, 17, 18, 22):
                recruit(p, species)
                p.save(dest)
            field_battle(p)
            p.save(dest)
            finish(p)
        return p
    finally:
        p.save(dest)


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("prefix")
    a.add_argument("--stage", default="army")
    args = a.parse_args()
    p = rich(args.prefix, args.stage)
    print("DETOUR STATE", summary(p.vm), flush=True)
