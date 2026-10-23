"""Export keyboard events, execute the full-graphics DOS build, compare states."""

import argparse, hashlib, json, struct, subprocess
from pathlib import Path
from machine import VM
from state import state
from config import ROOT, WORK


def native(path, variants=("CUR", "REF"), force=False):
    manifest = json.loads((WORK / "BUILD-MANIFEST.JSON").read_text(encoding="utf-8"))
    for source in (ROOT / "SRC").iterdir():
        if source.suffix.upper() in (".PAS", ".INC") and hashlib.sha256(
            source.read_bytes()
        ).hexdigest() != manifest["files"].get("BASE/SRC/" + source.name):
            raise RuntimeError(
                "Game sources changed; build the stand before checking a new version"
            )
    proof_path = Path(path).with_suffix(".proof.json")
    route_hash = hashlib.sha256(Path(path).read_bytes()).hexdigest()
    if proof_path.exists() and not force:
        saved = json.loads(proof_path.read_text(encoding="utf-8"))
        checks = {c["variant"]: c for c in saved.get("checks", [])}
        if saved.get("route_sha256") == route_hash and all(
            v in checks
            and checks[v]["result"] == "010000"
            and checks[v]["executable_sha256"]
            == hashlib.sha256(
                (WORK / ("DOS" + v) / "CODE/SGHOST.EXE").read_bytes()
            ).hexdigest()
            for v in variants
        ):
            print(
                "SAVED PASS",
                Path(path).name,
                {v: checks[v]["checkpoints"] for v in variants},
                flush=True,
            )
            return saved
    w = json.loads(Path(path).read_text(encoding="utf-8"))
    proof = []
    expected = []
    sessions = w.get("sessions", [w["inputs"]])
    disk = {}
    for session in sessions:
        vm = VM("CUR", w["seed"])
        vm.disk.update(disk)
        vm.run()
        for event in session:
            before = vm.pending["kind"]
            if before != event["at"]:
                raise AssertionError((len(expected), before, event))
            if before in ("step", "victory", "death"):
                expected.append(
                    (
                        {"step": 1, "victory": 2, "death": 3}[before],
                        bytes(state(vm).Campaign),
                        vm.read(vm.addresses[6][0], 4),
                    )
                )
            vm.run(event["scan"], idle_polls=event.get("idle_polls", 0))
        disk = {n: b for n, b in vm.disk.items() if n.endswith((".DAT", ".KB2"))}
        if vm.pending["kind"] in ("step", "victory", "death"):
            expected.append(
                (
                    {"step": 1, "victory": 2, "death": 3}[vm.pending["kind"]],
                    bytes(state(vm).Campaign),
                    vm.read(vm.addresses[6][0], 4),
                )
            )
    data = b"".join(
        struct.pack(
            "<BBi", e["scan"], 1 if e["at"] == "step" else 0, e.get("idle_polls", 0)
        )
        for e in w["inputs"]
    )
    commands = []
    for variant in variants:
        root = WORK / ("DOS" + variant) / "DATA"
        for name in ("STATES.BIN", "RESULT.BIN", "KB2.DAT", "RUN.KB2"):
            (root / name).unlink(missing_ok=True)
        commands.append(f"cd \\DOS{variant}\\DATA")
        for number, session in enumerate(sessions):
            (root / f"INPUT{number}.BIN").write_bytes(
                b"".join(
                    struct.pack(
                        "<BBi",
                        e["scan"],
                        int(e["at"] == "step"),
                        e.get("idle_polls", 0),
                    )
                    for e in session
                )
            )
            for name in (f"STATE{number}.BIN", f"EXIT{number}.BIN"):
                (root / name).unlink(missing_ok=True)
            commands.extend(
                [
                    f"copy /b INPUT{number}.BIN INPUT.BIN > NUL",
                    f"..\\CODE\\SGHOST.EXE {w['seed']} > RUN.LOG",
                    f"ren STATES.BIN STATE{number}.BIN",
                    f"ren RESULT.BIN EXIT{number}.BIN",
                ]
            )
    subprocess.run(
        [
            "pwsh",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "SOLVER/dos.ps1"),
            "-Work",
            str(WORK),
            "-Commands",
            "\n".join(commands),
        ],
        cwd=ROOT,
        check=True,
    )
    for variant in variants:
        root = WORK / ("DOS" + variant) / "DATA"
        raw = b"".join(
            (root / f"STATE{n}.BIN").read_bytes() for n in range(len(sessions))
        )
        stride = 46822
        if len(raw) % stride:
            raise AssertionError(("Truncated native checkpoint", variant, len(raw)))
        actual = [
            (
                struct.unpack_from("<H", raw, i)[0],
                raw[i + 2 : i + 46818],
                raw[i + 46818 : i + stride],
            )
            for i in range(0, len(raw), stride)
        ]
        for i, (a, e) in enumerate(zip(actual, expected)):
            if a != e:
                diffs = [n for n, (x, y) in enumerate(zip(a[1], e[1])) if x != y]
                raise AssertionError(
                    (
                        variant,
                        i,
                        "native campaign differs",
                        len(diffs),
                        diffs[:30],
                        "kinds",
                        a[0],
                        e[0],
                        "rngs",
                        a[2].hex(),
                        e[2].hex(),
                    )
                )
        if len(actual) != len(expected):
            raise AssertionError(
                (
                    variant,
                    "checkpoint count",
                    len(actual),
                    len(expected),
                    (root / "RUN.LOG").read_bytes(),
                )
            )
        for n in range(len(sessions) - 1):
            if (root / f"EXIT{n}.BIN").read_bytes() != b"\0\0\0":
                raise AssertionError((variant, "Intermediate exit failed", n))
        result = (root / f"EXIT{len(sessions) - 1}.BIN").read_bytes()
        if w.get("status") == {"kind": "exit", "code": 0} and result != b"\x01\0\0":
            raise AssertionError((variant, "No normal victory", result.hex()))
        proof.append(
            {
                "variant": variant,
                "checkpoints": len(actual),
                "campaign_bytes_per_checkpoint": 46816,
                "raw_states_sha256": hashlib.sha256(raw).hexdigest(),
                "result": result.hex(),
                "executable_sha256": hashlib.sha256(
                    (root.parent / "CODE/SGHOST.EXE").read_bytes()
                ).hexdigest(),
            }
        )
        print(
            "NATIVE PASS",
            variant,
            len(actual),
            "checkpoints",
            "result",
            result.hex(),
            flush=True,
        )
    report = {
        "route_sha256": route_hash,
        "input_binary_sha256": hashlib.sha256(data).hexdigest(),
        "reference": __import__("config").REFERENCE,
        "checks": proof,
    }
    proof_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return expected


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("witness")
    a.add_argument(
        "--force", action="store_true", help="Explicitly repeat a saved check"
    )
    args = a.parse_args()
    native(args.witness, force=args.force)
