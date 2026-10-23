"""A royal-reward route using an ordinary beneficial parchment event."""

from state import state, summary
from planning import component_labels
from solve import portal
from tactics import aim


def king_reward(p):
    if "objective:royal-reward" in p.notes:
        return
    g = state(p.vm).Campaign
    island = next((i + 1 for i, q in enumerate(g.QuestFlags) if q == 0), None)
    if island is None:
        raise RuntimeError("No completed royal quest")
    c = g.Castles[island - 1][0]
    target = c.X, c.Y
    labels, sizes, _ = component_labels(bytes(g.Map[island - 1]))
    positions = [
        (c.X + dx, c.Y + 1)
        for dx in (-1, 0, 1)
        if g.Map[island - 1][c.X + dx][c.Y + 1] in (0, 4)
        or 32 <= g.Map[island - 1][c.X + dx][c.Y + 1] < 48
    ]
    landing = max(positions, key=lambda xy: sizes.get(labels.get(xy), 0))
    portal(p, island, landing, connected=True)
    p.clear_nearby()
    if not p.goto(landing, safe=True):
        raise RuntimeError("Royal castle entrance unreachable")
    p.send(aim(landing, target))
    p.char("2")
    p.char("4")
    p.settle()
    if state(p.vm).Campaign.QuestFlags[island - 1] != 100:
        raise RuntimeError("Royal reward not received")
    p.notes.append("objective:royal-reward")
    print(
        "ROYAL REWARD",
        island,
        summary(p.vm),
        "capacity",
        state(p.vm).Campaign.ScrollCapacity,
        flush=True,
    )
