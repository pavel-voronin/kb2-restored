"""Read the packed Turbo Pascal state layout; never write game state for play."""

import ctypes as C, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = {
    "byte": C.c_uint8,
    "boolean": C.c_uint8,
    "shortint": C.c_int8,
    "word": C.c_uint16,
    "integer": C.c_int16,
    "longint": C.c_int32,
    "pointer": C.c_uint32,
    "text": C.c_uint8 * 256,
    "char": C.c_uint8,
}


class Cost(C.LittleEndianStructure):
    _pack_ = 1
    _fields_ = [("Price", C.c_uint16)]


BASE["tcreaturecost"] = Cost


def build_types():
    types = dict(BASE)
    for file in ("KBTYPES.PAS", "KBSTATE.PAS", "KBBTYPE.PAS"):
        source = (ROOT / "SRC" / file).read_bytes().decode("cp866")
        source = re.sub(r"\{.*?\}", "", source, flags=re.S)
        for name, body in re.findall(
            r"(\w+)\s*=\s*packed\s+record\b(.*?)\bend\s*;", source, re.I | re.S
        ):
            if name.lower() in types:
                continue
            fields = []
            for entry in body.split(";"):
                entry = entry.strip()
                if not entry:
                    continue
                names, kind = entry.split(":", 1)
                field_type = resolve(kind.strip(), types)
                for field in names.split(","):
                    fields.append((field.strip(), field_type))
            cls = type(
                name, (C.LittleEndianStructure,), {"_pack_": 1, "_fields_": fields}
            )
            types[name.lower()] = cls
    return types


def resolve(kind, types):
    kind = kind.strip().lower()
    if kind in types:
        return types[kind]
    m = re.match(r"string\[(\d+)\]$", kind)
    if m:
        return C.c_uint8 * (int(m[1]) + 1)
    m = re.match(r"array\[(.*?)\]\s+of\s+(.*)", kind, re.S)
    if m:
        t = resolve(m[2], types)
        dims = m[1].split(",")
        for d in reversed(dims):
            lo, hi = map(int, d.split(".."))
            t = t * (hi - lo + 1)
        return t
    raise ValueError(kind)


TYPES = build_types()
Game = TYPES["tgamestate"]
Campaign = TYPES["tcampaignstate"]
Battle = TYPES["tbattlestate"]
Creature = TYPES["tcreaturedefinition"]
assert C.sizeof(Game) == 50592, C.sizeof(Game)
assert C.sizeof(Campaign) == 46816


def state(vm):
    return Game.from_buffer_copy(vm.read(vm.addresses[0][0], C.sizeof(Game)))


def creatures(vm):
    return (Creature * 30).from_buffer_copy(
        vm.read(vm.addresses[5][0], C.sizeof(Creature) * 30)
    )


def pname(value):
    return bytes(value)[1 : 1 + value[0]].decode("cp866")


def summary(vm):
    s = state(vm)
    g = s.Campaign
    return dict(
        island=g.Island,
        hero=[g.Hero.X, g.Hero.Y],
        gold=g.Gold,
        power=g.MagicPower,
        leadership=g.Leadership,
        weeks=g.Weeks,
        days=g.Days,
        parts=g.MapParts,
        unlocked=g.UnlockedIslands,
        ship=bool(g.Flags.ShipOwned),
        sailing=bool(s.Runtime.ShipAbandonBlocked),
        grace=g.EnemyGrace,
        army=[[a.Species, a.Count] for a in g.Army if a.Species < 100],
        wizard=[s.World.WizardPosition.X, s.World.WizardPosition.Y],
    )


if __name__ == "__main__":
    import machine, json, sys

    vm = machine.VM(sys.argv[1] if len(sys.argv) > 1 else "CUR")
    vm.run()
    for key in (28, 80, 80, 80, 28):
        vm.run(key)
    print(json.dumps(summary(vm), ensure_ascii=False))
    g = state(vm).Campaign
    print("towns", [(t.X, t.Y) for t in g.Towns[0]])
    print("castles", [(t.X, t.Y) for t in g.Castles[0]])
    print("dwellings", [(t.X, t.Y, t.Species, t.Count) for t in g.Dwellings[0]])
    print(
        "treasures",
        [(x, y) for x in range(3, 64) for y in range(3, 64) if g.Map[0][x][y] == 10],
    )
    print(
        "creatures",
        [
            (i, pname(c.Name), c.Cost.Price, c.Defense, c.Attack)
            for i, c in enumerate(creatures(vm))
        ],
    )
