"""Build the stand in a separate directory, using TP7 for game and resources."""

import subprocess, json, hashlib
from config import ROOT, WORK, REFERENCE
from prepare import prepare, write
from native_prepare import prepare_native
from seeded_prepare import prepare_seeded


def build():
    prepare()
    prepare_native()
    prepare_seeded()
    commands = [
        "@echo off",
        "if exist BUILD.OK del BUILD.OK",
        "cd BASE\\SRC",
        r"..\..\PASCAL\TPC.EXE KB2.PAS /B /L > GAME.LOG",
        "if errorlevel 1 goto bad",
        r"..\..\PASCAL\TPC.EXE RSPACK.PAS /B /L > BUILD.LOG",
        "if errorlevel 1 goto bad",
        "if not exist DIST\\NUL mkdir DIST",
        "RSPACK.EXE > PACK.LOG",
        "if errorlevel 1 goto bad",
        r"cd ..\..",
    ]
    variants = ("CUR", "REF", "DOSCUR", "DOSREF", "PLAYCUR", "PLAYREF")
    for variant in variants:
        program = "SEEDED" if variant.startswith("PLAY") else "SGHOST"
        commands.extend(
            [
                f"cd {variant}\\CODE",
                rf"..\..\PASCAL\TPC.EXE {program}.PAS /B /GD > BUILD.LOG",
                "if errorlevel 1 goto bad",
                r"cd ..\..",
                rf"copy /b BASE\SRC\DIST\*.PIC {variant}\DATA > COPY.LOG",
                rf"copy /b BASE\SRC\DIST\*.FNT {variant}\DATA >> COPY.LOG",
            ]
        )
    commands.extend(
        ["echo OK>BUILD.OK", "goto done", ":bad", "echo FAILED>BUILD.ERR", ":done"]
    )
    write(WORK / "BUILDALL.BAT", "\n".join(commands) + "\n")
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
            "call BUILDALL.BAT",
        ],
        check=True,
    )
    if not (WORK / "BUILD.OK").is_file():
        raise RuntimeError(f"TP7 build failed; inspect logs in {WORK}")
    for variant in variants:
        log = (WORK / variant / "CODE/BUILD.LOG").read_text(errors="replace")
        if "bytes code" not in log:
            raise RuntimeError((variant, log[-1000:]))
        print(variant, log.splitlines()[-1], flush=True)
    manifest = {
        "reference": REFERENCE,
        "files": {
            str(p.relative_to(WORK)).replace("\\", "/"): hashlib.sha256(
                p.read_bytes()
            ).hexdigest()
            for p in WORK.rglob("*")
            if p.is_file()
            and p.suffix.upper() in (".PAS", ".INC", ".EXE", ".PIC", ".FNT", ".PCX")
        },
    }
    (WORK / "BUILD-MANIFEST.JSON").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print("BUILD PASS", WORK, flush=True)


if __name__ == "__main__":
    build()
