"""Deterministic actor forecast and interception on a time-expanded movement graph.

This is a search heuristic, not a replacement game engine. Every selected input
is executed by the Pascal guest. Unexpected encounters or forecast divergence
cause replanning from the observed guest state.
"""

from collections import deque
from state import state

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


class Forecast:
    def __init__(self, vm):
        s = state(vm)
        g = s.Campaign
        self.world = bytearray(bytes(g.Map[g.Island - 1]))
        self.difficulty = g.Difficulty
        self.wizard = [
            s.World.WizardPosition.X,
            s.World.WizardPosition.Y,
            s.World.WizardAge & 255,
        ]
        self.mage = [
            s.World.MagePosition.X,
            s.World.MagePosition.Y,
            s.World.MageAge & 255,
        ]
        self.seed = int.from_bytes(vm.read(vm.addresses[6][0], 4), "little")

    def rand(self, n):
        self.seed = (self.seed * 134775813 + 1) & 0xFFFFFFFF
        return (self.seed * n) >> 32

    def actor(self, p, tile):
        x, y, age = p
        if age > self.difficulty:
            age = 0
            self.world[x * 66 + y] = 0
            while True:
                x, y = self.rand(65), self.rand(65)
                if self.world[x * 66 + y] == 0:
                    break
            self.world[x * 66 + y] = tile
        else:
            age += 1
            dx, dy = [
                (-1, -1),
                (0, -1),
                (1, -1),
                (1, 0),
                (1, 1),
                (0, 1),
                (-1, 1),
                (-1, 0),
            ][self.rand(79) // 10]
            nx, ny = (x + dx) & 255, (y + dy) & 255
            if nx < 66 and ny < 66 and self.world[nx * 66 + ny] == 0:
                self.world[x * 66 + y] = 0
                self.world[nx * 66 + ny] = tile
                x, y = nx, ny
        p[:] = [x, y, age]


def component_labels(world):
    labels = {}
    sizes = {}
    paper = {}
    number = 0
    for x in range(2, 64):
        for y in range(2, 64):
            if (x, y) in labels or (
                world[x * 66 + y] not in (0, 4, 9, 10, 12, 28)
                and not 32 <= world[x * 66 + y] < 48
            ):
                continue
            number += 1
            todo = deque([(x, y)])
            labels[x, y] = number
            count = 0
            scrolls = 0
            while todo:
                xx, yy = todo.popleft()
                count += 1
                scrolls += world[xx * 66 + yy] == 9
                for dx, dy, key in DIRECTIONS:
                    pos = xx + dx, yy + dy
                    if pos in labels or not (2 <= pos[0] <= 63 and 2 <= pos[1] <= 63):
                        continue
                    tile = world[pos[0] * 66 + pos[1]]
                    if tile not in (0, 4, 9, 10, 12, 28) and not 32 <= tile < 48:
                        continue
                    labels[pos] = number
                    todo.append(pos)
            sizes[number] = count
            paper[number] = scrolls
    return labels, sizes, paper


def forecast_landing(f, vm, island):
    s = state(vm)
    g = s.Campaign
    world = bytearray(bytes(g.Map[island - 1]))
    if island == g.Island:
        for p in (f.wizard, f.mage):
            world[p[0] * 66 + p[1]] = 0
    for tile in (12, 28, 0):
        for _ in range(10000):
            x, y = f.rand(65), f.rand(65)
            if world[x * 66 + y] == 0:
                break
        else:
            return (-1, -1)
        if tile:
            world[x * 66 + y] = tile
    return x, y
