"""Replay a keyboard witness without invoking any route planner."""

import argparse, hashlib, json, time
from pathlib import Path
from machine import VM
from state import state, summary


def replay(path, variants=("REF", "CUR"), save=None):
    witness = json.loads(Path(path).read_text(encoding="utf-8"))
    machines = [VM(v, witness["seed"]) for v in variants]
    for vm in machines:
        vm.run()
    checkpoints = []
    started = time.monotonic()
    for number, entry in enumerate(witness["inputs"], 1):
        events = []
        for vm in machines:
            if vm.pending["kind"] != entry["at"]:
                raise AssertionError(
                    (number, vm.variant, "input phase", vm.pending, entry)
                )
            event = vm.run(entry["scan"], idle_polls=entry.get("idle_polls", 0))
            events.append(event["kind"])
        if len(set(events)) != 1:
            raise AssertionError((number, "different events", events))
        if events[0] in ("step", "victory", "death", "exit"):
            values = [bytes(state(vm).Campaign) for vm in machines]
            if any(value != values[0] for value in values[1:]):
                diffs = [
                    i for i, (a, b) in enumerate(zip(values[0], values[-1])) if a != b
                ]
                raise AssertionError(
                    (
                        number,
                        "campaign differs",
                        len(diffs),
                        diffs[:20],
                        [summary(vm) for vm in machines],
                    )
                )
            rngs = [vm.read(vm.addresses[6][0], 4).hex() for vm in machines]
            if len(set(rngs)) != 1:
                raise AssertionError((number, "RNG differs", rngs))
            checkpoints.append(
                {
                    "input": number,
                    "kind": events[0],
                    "campaign_sha256": hashlib.sha256(values[0]).hexdigest(),
                    "rng": rngs[0],
                }
            )
        if number % 500 == 0:
            print("replay", number, "/", len(witness["inputs"]), flush=True)
    result = {
        "seed": witness["seed"],
        "inputs": len(witness["inputs"]),
        "variants": list(variants),
        "final": machines[0].pending,
        "summary": summary(machines[0]),
        "checkpoints": checkpoints,
        "elapsed_host_seconds": time.monotonic() - started,
    }
    if save:
        Path(save).write_text(
            json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
        )
    print(
        "REPLAY PASS",
        len(checkpoints),
        "equal campaigns",
        result["final"],
        result["summary"],
        flush=True,
    )
    return result


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("witness")
    a.add_argument("--save")
    args = a.parse_args()
    replay(args.witness, save=args.save)
