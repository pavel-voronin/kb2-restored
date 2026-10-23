"""Extract a reproducible input prefix, with its actual state and input phase."""

import argparse, json
from pathlib import Path
from play import Play
from state import state


def extract(path, out, until):
    w = json.loads(Path(path).read_text(encoding="utf-8"))
    p = Play(w["seed"])
    seen_battle = False
    for number, event in enumerate(w["inputs"][5:], 6):
        if p.vm.pending["kind"] != event["at"]:
            raise AssertionError((number, p.vm.pending, event))
        p.send(event["scan"], event.get("idle_polls", 0))
        seen_battle |= p.vm.battle_active
        if p.vm.pending["kind"] != "step":
            continue
        g = state(p.vm).Campaign
        if (
            (until == "maps" and g.MapParts == 5)
            or (
                until == "battle"
                and seen_battle
                and state(p.vm).Runtime.BattleResult == 1
            )
            or until == str(number)
        ):
            p.save(out)
            print("PREFIX", number, out, flush=True)
            return p
    raise RuntimeError("Requested checkpoint not reached")


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("route")
    a.add_argument("out")
    a.add_argument("--until", default="maps")
    args = a.parse_args()
    extract(args.route, args.out, args.until)
