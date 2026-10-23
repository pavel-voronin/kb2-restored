"""Continue a campaign after saving, exiting and starting a new DOS process."""

import json
import time
from pathlib import Path
from machine import VM
from play import Play
from state import summary
from solve import finish


def save_reload(prefix, out):
    p = Play.resume(prefix)
    p.send(31)
    p.settle()
    saved = summary(p.vm)
    p.send(68)
    p.send(21)
    p.send(21)
    for ch in "run":
        p.char(ch)
    try:
        p.send(28)
    except RuntimeError:
        if p.vm.pending != {"kind": "exit", "code": 0}:
            raise
    if "RUN.KB2" not in p.vm.disk:
        raise RuntimeError("Named save was not written")
    first = p.events.copy()
    disk = {n: b for n, b in p.vm.disk.items() if n.endswith((".DAT", ".KB2"))}
    q = Play.__new__(Play)
    q.vm = VM(p.vm.variant, p.vm.seed)
    q.vm.disk.update(disk)
    q.events = []
    q.notes = p.notes + ["effect:save-reload"]
    q.avoid = set()
    q.started = time.monotonic()
    q.vm.run()
    q.send(80)
    q.send(28)
    loaded = summary(q.vm)
    for name in ("gold", "power", "leadership", "weeks", "parts", "army"):
        if saved[name] != loaded[name]:
            raise RuntimeError(("Reload differs", name, saved[name], loaded[name]))
    finish(q)
    q.save(out)
    witness = json.loads(Path(out).read_text(encoding="utf-8"))
    witness["sessions"] = [first, q.events]
    witness["inputs"] = first + q.events
    Path(out).write_text(
        json.dumps(witness, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("SAVE/RELOAD VICTORY", len(first), len(q.events), flush=True)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("prefix")
    parser.add_argument("out")
    args = parser.parse_args()
    save_reload(args.prefix, args.out)
