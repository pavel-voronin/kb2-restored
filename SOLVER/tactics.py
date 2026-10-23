"""Read-only tactical policy. Every action is an ordinary scan-code input."""

from collections import deque
from state import state, Battle
from play import DIRECTIONS


def aim(origin, target):
    dx = (target[0] > origin[0]) - (target[0] < origin[0])
    dy = (target[1] > origin[1]) - (target[1] < origin[1])
    return next((key for x, y, key in DIRECTIONS if (x, y) == (dx, dy)), 28)


def distance(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]))


def battle_state(vm):
    return Battle.from_buffer_copy(vm.read(vm.addresses[4][0], vm.addresses[4][1]))


def choose(vm):
    s = state(vm)
    c = battle_state(vm)
    field = s.Runtime.BattleField
    enemy = [
        (x, y, (field[x][y] - 32) // 3)
        for x in range(6)
        for y in range(5)
        if 32 <= field[x][y] <= 44
    ]
    players = [
        (x, y, (field[x][y] - 112) // 3)
        for x in range(6)
        for y in range(5)
        if 112 <= field[x][y] <= 124
    ]
    if not enemy:
        return 28
    if vm.battle_mode == "magic":
        for spell in (11, 9, 10, 8, 13, 7, 12):
            if s.Campaign.Scrolls[spell]:
                return spell - 5
        return 1
    x, y, color = vm.battle_cursor
    origin = x, y
    strongest = max(enemy, key=lambda p: c.Enemy[p[2]].AttackPower)
    if color == 12:
        return aim(origin, strongest)
    if color == 15:
        spell = vm.battle_spell
        if spell in (9, 10, 11, 13):
            return aim(origin, strongest)
        if spell in (8, 12):
            unit = min(
                players,
                key=lambda p: (
                    c.Player[p[2]].HitPoints / max(1, c.Player[p[2]].InitialCount)
                ),
            )
            return aim(origin, unit)
        if not c.TeleportSelected:
            unit = max(
                players,
                key=lambda p: (c.Player[p[2]].Species == 23, c.Player[p[2]].HitPoints),
            )
            return aim(origin, unit)
        cells = [
            (xx, yy)
            for xx in range(6)
            for yy in range(5)
            if field[xx][yy] == 0 and any(distance((xx, yy), e[:2]) == 1 for e in enemy)
        ]
        return (
            aim(origin, min(cells, key=lambda xy: distance(origin, xy))) if cells else 1
        )
    if color == 14:
        nearby = [e for e in enemy if distance(origin, e[:2]) == 1]
        if nearby:
            return aim(origin, max(nearby, key=lambda e: c.Enemy[e[2]].AttackPower))
        q = deque([origin])
        prev = {origin: None}
        goal = None
        while q:
            xy = q.popleft()
            if any(distance(xy, e[:2]) == 1 for e in enemy):
                goal = xy
                break
            for dx, dy, key in DIRECTIONS:
                p = xy[0] + dx, xy[1] + dy
                if (
                    p in prev
                    or not (0 <= p[0] < 6 and 0 <= p[1] < 5)
                    or field[p[0]][p[1]] != 0
                ):
                    continue
                prev[p] = xy, key
                q.append(p)
        if goal is None:
            return 57
        while prev[goal] is not None:
            old, key = prev[goal]
            if old == origin:
                return key
            goal = old
        return 57
    if c.EnemyPhaseFinished and any(
        s.Campaign.Scrolls[spell] for spell in (7, 8, 9, 10, 11, 13)
    ):
        return 22
    ready = [p for p in players if c.CanMove[p[2]]]
    if not ready:
        return 18
    shooter = [
        p
        for p in ready
        if c.Player[p[2]].Shots > 0
        and not any(distance(p[:2], e[:2]) == 1 for e in enemy)
    ]
    adjacent = [p for p in ready if any(distance(p[:2], e[:2]) == 1 for e in enemy)]
    flyer = [p for p in ready if c.Player[p[2]].CanFly]
    unit = (
        shooter
        or adjacent
        or flyer
        or sorted(ready, key=lambda p: min(distance(p[:2], e[:2]) for e in enemy))
    )[0]
    if origin != unit[:2]:
        return aim(origin, unit)
    if unit in shooter:
        return 31
    if unit in flyer and not unit in adjacent:
        return 33
    return 50


def fight(p, limit=4000):
    for turn in range(limit):
        if p.vm.pending["kind"] != "key":
            return
        if not p.vm.battle_active:
            text = " ".join(p.vm.dialog)
            if "Дpаться будешь" in text:
                p.send(21)
            else:
                p.send(28)
        else:
            p.send(choose(p.vm))
        if p.vm.pending["kind"] == "step":
            print(
                "BATTLE FINISHED",
                turn,
                "result",
                state(p.vm).Runtime.BattleResult,
                flush=True,
            )
            return
    raise RuntimeError(("Tactical policy stuck", p.vm.pending, p.vm.text[-15:]))
