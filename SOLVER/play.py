"""State-aware, keyboard-only route search and an auditable input transcript."""

from __future__ import annotations
import collections, json, time, heapq, hashlib, pickle, zlib
from pathlib import Path
from machine import VM, KEYS
from state import state, summary
from config import WORK

DIRECTIONS = [
    (-1, -1, 71),
    (0, -1, 72),
    (1, -1, 73),
    (-1, 0, 75),
    (1, 0, 77),
    (-1, 1, 79),
    (0, 1, 80),
    (1, 1, 81),
]
CHARSCAN = {chr(v): k for k, v in KEYS.items() if v}


class Play:
    @staticmethod
    def cache_path(raw, variant):
        digest = hashlib.sha256(raw)
        digest.update((WORK / variant / "CODE/SGHOST.EXE").read_bytes())
        digest.update(Path(__file__).with_name("machine.py").read_bytes())
        return WORK / "SNAPSHOTS" / (digest.hexdigest() + ".bin")

    @classmethod
    def resume(cls, path):
        raw = Path(path).read_bytes()
        witness = json.loads(raw)
        variant = witness.get("variant", "CUR")
        cached = cls.cache_path(raw, variant)
        if cached.exists():
            # Only locally generated caches are read. They are never route fixtures.
            p = cls.__new__(cls)
            p.vm = VM(variant, witness["seed"])
            p.vm.restore(pickle.loads(zlib.decompress(cached.read_bytes())))
            p.events = witness["inputs"]
            p.notes = witness.get("notes", [])
            p.avoid = set()
            p.started = time.monotonic()
            print("RESUME SNAPSHOT", Path(path).name, len(p.events), flush=True)
            return p
        p = cls(witness["seed"], variant)
        for e in witness["inputs"][5:]:
            p.send(e["scan"], e.get("idle_polls", 0))
        p.notes = witness.get("notes", [])
        p.save(path)
        return p

    def __init__(self, seed=12345, variant="CUR"):
        self.vm = VM(variant, seed)
        self.events = []
        self.notes = []
        self.avoid = set()
        self.started = time.monotonic()
        self.vm.run()
        for k in (28, 80, 80, 80, 28):
            self.send(k)

    def send(self, key, idle_polls=0):
        before = self.vm.pending["kind"]
        self.events.append(
            {
                "scan": key,
                "at": before,
                **({"idle_polls": idle_polls} if idle_polls else {}),
            }
        )
        result = self.vm.run(key, idle_polls=idle_polls)
        if result["kind"] in ("fault", "limit", "exit", "death"):
            raise RuntimeError((result, self.vm.text[-8:], summary(self.vm)))
        return result

    def char(self, ch):
        return self.send(CHARSCAN[ch])

    def enter_number(self, n):
        for ch in str(n):
            if self.vm.pending["kind"] != "key":
                raise RuntimeError("Quantity ended early")
            self.char(ch)
        if self.vm.pending["kind"] == "key":
            self.send(28)

    def settle(self, choice="1", maxkeys=20):
        for _ in range(maxkeys):
            if self.vm.pending["kind"] != "key":
                return
            text = " ".join(self.vm.dialog)
            if "Раздать воинам" in text and "ЗОЛОТО:" in text:
                self.char(choice)
            elif "Дpаться будешь" in text:
                self.send(49)
            else:
                self.send(1)
        raise RuntimeError(("Dialog did not settle", self.vm.text[-20:]))

    def path(self, target, allowed=None):
        s = state(self.vm)
        g = s.Campaign
        world = g.Map[g.Island - 1]
        start = (g.Hero.X, g.Hero.Y)
        targets = {target} if isinstance(target, tuple) else set(target)
        allowed = allowed or (
            {0, 4, 10, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47}
            if not s.Runtime.ShipAbandonBlocked
            else set(range(32, 64)) | {4, 14}
        )
        todo = collections.deque([start])
        prev = {start: None}
        goal = None
        while todo:
            xy = todo.popleft()
            if xy in targets and xy != start:
                goal = xy
                break
            for dx, dy, key in DIRECTIONS:
                pos = (xy[0] + dx, xy[1] + dy)
                if (
                    pos in prev
                    or pos in self.avoid
                    or not (2 <= pos[0] <= 63 and 2 <= pos[1] <= 63)
                ):
                    continue
                tile = world[pos[0]][pos[1]]
                if tile not in allowed and not (
                    pos in targets and (tile < 48 and tile not in (1, 3))
                ):
                    continue
                prev[pos] = (xy, key)
                todo.append(pos)
        if goal is None:
            return None
        route = []
        while prev[goal] is not None:
            last, key = prev[goal]
            route.append((key, goal))
            goal = last
        return list(reversed(route))

    def work_path(self, target):
        s = state(self.vm)
        g = s.Campaign
        world = g.Map[g.Island - 1]
        start = (g.Hero.X, g.Hero.Y, 0, 0, 0)
        if s.Runtime.ShipAbandonBlocked:
            return None
        caps = (min(g.Carpenters, 4), min(g.Woodcutters, 4), min(g.Stonecutters, 4))
        pq = [(0, start)]
        cost = {start: 0}
        prev = {start: None}
        goal = None
        while pq:
            value, node = heapq.heappop(pq)
            if value != cost[node]:
                continue
            x, y, *used = node
            if (x, y) == target and node != start:
                goal = node
                break
            for dx, dy, key in DIRECTIONS:
                nx, ny = x + dx, y + dy
                if not (2 <= nx <= 63 and 2 <= ny <= 63):
                    continue
                tile = world[nx][ny]
                job = 0
                newused = list(used)
                if (
                    tile in (0, 4, 10)
                    or 32 <= tile < 48
                    or (
                        (nx, ny) == target
                        and tile in (2, 5, 7, 8, 9, 11, 12, 14, 18, 22, 23, 28)
                    )
                ):
                    pass
                elif 48 <= tile < 64:
                    job = 1
                elif 64 <= tile < 80:
                    job = 2
                elif 80 <= tile < 96:
                    job = 4
                else:
                    continue
                if job:
                    if dx and dy:
                        continue
                    resource = {1: 0, 2: 1, 4: 2}[job]
                    newused[resource] += 1
                    if newused[resource] > caps[resource]:
                        continue
                nxt = (nx, ny, *newused)
                newcost = value + (5 if job else 1)
                if newcost < cost.get(nxt, 10**9):
                    cost[nxt] = newcost
                    prev[nxt] = (node, key, (nx, ny), job)
                    heapq.heappush(pq, (newcost, nxt))
        if goal is None:
            return None
        result = []
        while prev[goal] is not None:
            old, key, pos, job = prev[goal]
            result.append((key, pos, job))
            goal = old
        return list(reversed(result))

    def work(self, job, key):
        self.send(17)
        self.char(str(job))
        self.send(key)
        self.settle()

    def goto(self, target, settle=True, maxsteps=400, safe=False):
        for _ in range(maxsteps):
            if safe:
                self.clear_nearby()
            g = state(self.vm).Campaign
            if (g.Hero.X, g.Hero.Y) == target:
                return True
            path = self.path(target)
            if not path:
                work = self.work_path(target)
                if not work:
                    return False
                key, pos, job = work[0]
                if job:
                    self.work(job, key)
                    continue
            else:
                key, pos = path[0]
            tile = g.Map[g.Island - 1][pos[0]][pos[1]]
            self.send(key)
            if self.vm.pending["kind"] == "key":
                if pos == target and tile in (2, 5, 7, 8, 11, 12, 18, 22, 23, 28):
                    return True
                if settle:
                    self.settle()
                else:
                    return False
            actual = state(self.vm).Campaign.Hero
            if (actual.X, actual.Y) == target or (pos == target and tile == 11):
                return True
        return False

    def collect(self, limit=200):
        count = 0
        for _ in range(limit):
            g = state(self.vm).Campaign
            targets = [
                (x, y)
                for x in range(3, 64)
                for y in range(3, 64)
                if g.Map[g.Island - 1][x][y] == 10
            ]
            path = self.path(targets)
            if not path:
                break
            key, pos = path[0]
            target = path[-1][1]
            root = self.checkpoint()
            try:
                if len(path) == 1 and g.Income < 2000:
                    for k in range(256):
                        self.rewind(root)
                        self.send(key, idle_polls=402 * k)
                        if state(self.vm).Campaign.Income > g.Income:
                            break
                    else:
                        raise RuntimeError("No income timing")
                else:
                    self.send(key)
                if self.vm.pending["kind"] == "key":
                    self.settle()
                if pos == target:
                    count += 1
            except RuntimeError:
                self.rewind(root)
                self.avoid.add(pos)
        self.avoid.clear()
        print("collect", count, summary(self.vm), flush=True)
        return count

    def component(self):
        g = state(self.vm).Campaign
        world = g.Map[g.Island - 1]
        start = (g.Hero.X, g.Hero.Y)
        q = collections.deque([start])
        seen = {start}
        while q:
            x, y = q.popleft()
            for dx, dy, key in DIRECTIONS:
                pos = x + dx, y + dy
                if pos in seen or not (2 <= pos[0] <= 63 and 2 <= pos[1] <= 63):
                    continue
                if (
                    world[pos[0]][pos[1]] not in (0, 4, 9, 10, 12, 28)
                    and not 32 <= world[pos[0]][pos[1]] < 48
                ):
                    continue
                seen.add(pos)
                q.append(pos)
        return seen

    def wizard_timed(
        self,
        option=None,
        offer=None,
        travel=None,
        landing_target=None,
        landing_connected=False,
        maxtries=20000,
    ):
        from planning import Forecast, forecast_landing, component_labels

        if travel is not None:
            labels, sizes, papers = component_labels(
                bytes(state(self.vm).Campaign.Map[travel - 1])
            )
        for turn in range(20):
            s = state(self.vm)
            g = s.Campaign
            hero = (g.Hero.X, g.Hero.Y)
            if (
                s.World.WizardAge <= g.Difficulty
                and max(
                    abs(hero[0] - s.World.WizardPosition.X),
                    abs(hero[1] - s.World.WizardPosition.Y),
                )
                > 4
            ):
                self.send(47)
                self.settle()
                continue
            root = self.checkpoint()
            model = Forecast(self.vm)
            seed = model.seed
            stride = 3 if g.Gold > 999999 else 1
            for k in range(maxtries if travel is None else max(maxtries, 250000)):
                if k:
                    for _ in range(stride):
                        seed = (seed * 134775813 + 1) & 0xFFFFFFFF
                f = object.__new__(Forecast)
                f.world = model.world.copy()
                f.difficulty = model.difficulty
                f.wizard = model.wizard.copy()
                f.mage = model.mage.copy()
                f.seed = seed
                f.actor(f.wizard, 12)
                target = tuple(f.wizard[:2])
                if (
                    target == hero
                    or max(abs(hero[0] - target[0]), abs(hero[1] - target[1])) > 3
                ):
                    continue
                todo = collections.deque([hero])
                prev = {hero: None}
                found = False
                while todo:
                    xy = todo.popleft()
                    if xy == target:
                        found = True
                        break
                    for dx, dy, key in DIRECTIONS:
                        pos = xy[0] + dx, xy[1] + dy
                        if pos in prev or not (2 <= pos[0] <= 63 and 2 <= pos[1] <= 63):
                            continue
                        if max(abs(pos[0] - hero[0]), abs(pos[1] - hero[1])) > 3:
                            continue
                        if (
                            f.world[pos[0] * 66 + pos[1]] not in (0, 4)
                            and pos != target
                        ):
                            continue
                        prev[pos] = (xy, key)
                        todo.append(pos)
                if not found:
                    continue
                pos = target
                keys = []
                while prev[pos] is not None:
                    old, key = prev[pos]
                    keys.append(key)
                    pos = old
                keys.reverse()
                if len(keys) > 3 or (travel is not None and len(keys) != 1):
                    continue
                if len(keys) == 1:
                    # The native pursuit scan can either consume the mage turn or leave it
                    # to MoveRoamer. Keep both RNG branches; the guest decides which occurred.
                    import copy

                    plausible = False
                    for random_mage in (False, True):
                        candidate = copy.deepcopy(f)
                        if random_mage:
                            candidate.actor(candidate.mage, 28)
                        offered = None
                        if g.WizardRelations[g.Island - 1] > 4:
                            while True:
                                offered = candidate.rand(10) + 1
                                if offered < 7:
                                    break
                        if offer == "($500000)" and offered != 2:
                            continue
                        if offer == "Изменить волшебства" and offered != 1:
                            continue
                        if travel is not None:
                            landing = forecast_landing(candidate, self.vm, travel)
                            label = labels.get(landing)
                            if label is None:
                                continue
                            if landing_target is not None:
                                if landing_connected and label != labels.get(
                                    landing_target
                                ):
                                    continue
                                if (
                                    max(
                                        abs(landing[0] - landing_target[0]),
                                        abs(landing[1] - landing_target[1]),
                                    )
                                    > 6
                                ):
                                    continue
                            elif sizes[label] < min(100, max(sizes.values()) // 2):
                                continue
                        plausible = True
                        break
                    if not plausible:
                        continue
                self.rewind(root)
                self.send(keys[0], idle_polls=402 * k)
                if (
                    self.vm.pending["kind"] == "key"
                    and not g.Flags.InstructionsShown
                    and state(self.vm).Campaign.Flags.InstructionsShown
                ):
                    self.send(28)
                if self.vm.pending["kind"] == "key" and "ВОЛШЕБНИК" in self.vm.dialog:
                    if offer and not any(
                        x.startswith("6)") and offer in x for x in self.vm.dialog
                    ):
                        self.rewind(root)
                        continue
                    if option is None:
                        self.send(1)
                    else:
                        self.char(str(option))
                    if travel is not None:
                        if self.vm.pending["kind"] != "key":
                            self.rewind(root)
                            continue
                        self.char(str(travel))
                        self.settle()
                        if (
                            (
                                landing_connected
                                and landing_target not in self.component()
                            )
                            or state(self.vm).Campaign.Island != travel
                            or (
                                landing_target is not None
                                and (
                                    max(
                                        abs(
                                            state(self.vm).Campaign.Hero.X
                                            - landing_target[0]
                                        ),
                                        abs(
                                            state(self.vm).Campaign.Hero.Y
                                            - landing_target[1]
                                        ),
                                    )
                                    > 6
                                )
                            )
                        ):
                            self.rewind(root)
                            continue
                    print(
                        "timed wizard",
                        k,
                        "polls",
                        402 * k,
                        "travel",
                        travel,
                        summary(self.vm),
                        flush=True,
                    )
                    return True
                if self.vm.pending["kind"] == "key":
                    self.rewind(root)
                    continue
                # Move one legal step along the interception; recompute from real guest state.
                break
            else:
                self.rewind(root)
                return False
        return False

    def clear_nearby(self):
        for attempt in range(5):
            g = state(self.vm).Campaign
            x, y = g.Hero.X, g.Hero.Y
            hazards = [
                (xx, yy)
                for xx in range(max(2, x - 2), min(64, x + 3))
                for yy in range(max(2, y - 2), min(64, y + 3))
                if g.Map[g.Island - 1][xx][yy] in (5, 28)
            ]
            if not hazards:
                return
            if not g.TornadoCharges:
                raise RuntimeError(("Need tornado", hazards, summary(self.vm)))
            self.send(20)
            self.settle()
        raise RuntimeError("Unable to clear nearby enemies")

    def paper(self, target, wanted="double-gold"):
        # Reach an adjacent square, preserving the scroll until the selected timing.
        for _ in range(600):
            self.clear_nearby()
            path = self.path(target)
            if not path:
                work = self.work_path(target)
                if not work:
                    return False
                key, pos, job = work[0]
                if job:
                    self.work(job, key)
                else:
                    self.send(key)
                    self.settle()
                continue
            if len(path) == 1:
                break
            self.send(path[0][0])
            self.settle()
        else:
            return False
        self.clear_nearby()
        key = self.path(target)[0][0]
        root = self.checkpoint()
        before = state(self.vm).Campaign.Gold
        before_quests = tuple(state(self.vm).Campaign.QuestFlags)
        chart = bool(
            state(self.vm).Campaign.Flags.PaperChartPresent[
                state(self.vm).Campaign.Island - 1
            ]
        )
        for k in range(1000):
            self.rewind(root)
            self.send(key, idle_polls=402 * k)
            g = state(self.vm).Campaign
            picked = g.Map[g.Island - 1][target[0]][target[1]] != 9
            good = picked and (
                chart
                or (wanted == "double-gold" and g.Gold == before * 2 and before > 0)
                or (
                    wanted == "clear-quest"
                    and any(
                        old != 0 and new == 0
                        for old, new in zip(before_quests, g.QuestFlags)
                    )
                )
            )
            if good:
                self.settle()
                print("paper", k, chart, summary(self.vm), flush=True)
                return True
        self.rewind(root)
        return False

    def wait_week(self):
        self.send(18)
        self.settle()

    def save(self, path):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(
            json.dumps(
                {
                    "seed": self.vm.seed,
                    "variant": self.vm.variant,
                    "inputs": self.events,
                    "summary": summary(self.vm),
                    "status": self.vm.pending,
                    "notes": self.notes,
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        if self.vm.pending["kind"] in ("step", "key"):
            cached = self.cache_path(Path(path).read_bytes(), self.vm.variant)
            cached.parent.mkdir(parents=True, exist_ok=True)
            cached.write_bytes(zlib.compress(pickle.dumps(self.vm.snapshot()), 1))

    def checkpoint(self):
        return (self.vm.snapshot(), len(self.events), len(self.notes))

    def rewind(self, p):
        self.vm.restore(p[0])
        del self.events[p[1] :]
        del self.notes[p[2] :]
