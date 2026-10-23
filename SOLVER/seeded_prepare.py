"""Prepare ordinary, interactive DOS builds with only the new-game seed hook."""

import re, shutil
from config import ROOT, WORK
from prepare import write


def prepare_seeded():
    for name in ("CUR", "REF"):
        target = WORK / ("PLAY" + name) / "CODE"
        target.mkdir(parents=True, exist_ok=True)
        (target.parent / "DATA").mkdir(parents=True, exist_ok=True)
        source = ROOT / "SRC" if name == "CUR" else WORK / "REF/SRC"
        for p in source.iterdir():
            if p.suffix.upper() in (".PAS", ".INC"):
                shutil.copy2(p, target / p.name.upper())
        p = target / "KBSTART.PAS"
        s = p.read_bytes().decode("cp866").replace("\r\n", "\n")
        pos = s.index("implementation") + len("implementation")
        m = re.search(r"\buses\s+", s[pos:])
        at = pos + m.end()
        s = s[:at] + "RSeed, " + s[at:]
        s = s.replace(
            "  PrepareCampaign(MenuChoice);",
            "  UseRandomSeed(NewGameSeed);\n  PrepareCampaign(MenuChoice);",
        )
        write(p, s)
        write(
            target / "RSEED.PAS",
            """unit RSeed;
interface
var NewGameSeed: longint;
implementation
end.
""",
        )
        write(
            target / "SEEDED.PAS",
            """program SeededGame;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}
uses KBApp, KBRandom, RSeed;
var Error: integer;
begin
  Val(ParamStr(1), NewGameSeed, Error);
  if Error <> 0 then Halt(1);
  UseRandomSeed(NewGameSeed);
  RunGame;
end.
""",
        )


if __name__ == "__main__":
    prepare_seeded()
