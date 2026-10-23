"""Legal army, reserve, defeat and sea-travel objectives."""

from collections import deque
from state import state, summary
from config import WORK
from play import DIRECTIONS


def army_recovery(p):
    import tactics
    from detour import field_battle

    before = sum(a.Species < 100 for a in state(p.vm).Campaign.Army)
    p.send(32)
    p.char("0")
    p.settle()
    assert sum(a.Species < 100 for a in state(p.vm).Campaign.Army) == before - 1
    p.notes.append("effect:dismiss")
    p.save(WORK / "SEARCH/recovery-dismissed.json")
    original = tactics.choose
    changed = False

    def choose(vm):
        nonlocal changed
        if not changed and vm.battle_cursor[2] == 0:
            count = tactics.battle_state(vm).PlayerCount
            p.send(30)
            p.char("1")
            withdrawn = tactics.battle_state(vm).PlayerCount
            p.send(15)
            p.char("1")
            returned = tactics.battle_state(vm).PlayerCount
            p.send(1)
            print("RESERVE COUNTS", count, withdrawn, returned, flush=True)
            if (withdrawn, returned) != (count - 1, count):
                raise RuntimeError("Reserve exchange failed")
            p.notes.append("effect:reserve")
            changed = True
            return 68
        return original(vm)

    tactics.choose = choose
    try:
        try:
            field_battle(p)
        except RuntimeError as e:
            if str(e) != "Field battle not won":
                raise
        if not changed or state(p.vm).Runtime.BattleResult != 2:
            raise RuntimeError("Expected defeat was not reached")
        p.notes.append("effect:defeat-recovery")
        p.save(WORK / "SEARCH/recovery-after-defeat.json")
        print("DEFEAT RECOVERED", summary(p.vm), flush=True)
    finally:
        tactics.choose = original


def sea_landing(p):
    old_island = state(p.vm).Campaign.Island
    target_island = 2 if old_island != 2 else 1
    p.char(str(target_island))
    p.settle()
    g = state(p.vm).Campaign
    start = g.Hero.X, g.Hero.Y
    todo = deque([start])
    prev = {start: None}
    goal = None
    while todo:
        x, y = todo.popleft()
        tile = g.Map[target_island - 1][x][y]
        if (x, y) != start and (tile == 0 or 32 <= tile <= 47):
            goal = x, y
            break
        for dx, dy, key in DIRECTIONS:
            pos = x + dx, y + dy
            if pos in prev or not (2 <= pos[0] <= 63 and 2 <= pos[1] <= 63):
                continue
            value = g.Map[target_island - 1][pos[0]][pos[1]]
            if value == 0 or 32 <= value <= 63:
                prev[pos] = (x, y), key
                todo.append(pos)
    if goal is None:
        raise RuntimeError("No sea landing")
    keys = []
    while prev[goal] is not None:
        goal, key = prev[goal]
        keys.append(key)
    for key in reversed(keys):
        p.send(key)
        p.settle()
    if state(p.vm).Runtime.ShipAbandonBlocked:
        raise RuntimeError("Still on ship")
    p.notes.append("effect:sea-landing")
    p.save(WORK / "SEARCH/after-sea-landing.json")
    g = state(p.vm).Campaign
    if not p.goto((g.Ship.X, g.Ship.Y)):
        raise RuntimeError("Cannot reboard ship")
    p.settle()
    if not state(p.vm).Runtime.ShipAbandonBlocked:
        raise RuntimeError("Not reboarded")
    p.send(49)
