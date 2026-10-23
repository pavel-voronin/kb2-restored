import re, subprocess, shutil
from config import ROOT, WORK, REFERENCE


def write(p, s):
    p.write_bytes(s.replace("\r\n", "\n").replace("\n", "\r\n").encode("cp866"))


def prepare():
    WORK.mkdir(parents=True, exist_ok=True)
    for name in ("CUR", "REF"):
        dest = WORK / name
        dest.mkdir(exist_ok=True)
        if name == "REF":
            archive = WORK / "seedref.tar"
            subprocess.run(
                [
                    "git",
                    "archive",
                    "--format=tar",
                    f"--output={archive}",
                    REFERENCE,
                    "SRC",
                ],
                cwd=ROOT,
                check=True,
            )
            subprocess.run(["tar", "-xf", str(archive), "-C", str(dest)], check=True)
            src = dest / "SRC"
        else:
            src = ROOT / "SRC"
        target = dest / "CODE"
        target.mkdir(exist_ok=True)
        for p in src.iterdir():
            if p.suffix.upper() in (".PAS", ".INC"):
                shutil.copy2(p, target / p.name.upper())
        write(
            target / "SBRIDGE.PAS",
            """unit SBridge;
    {$G+,R-,S-,A+}
    interface
    procedure Mark(Kind: word; P: pointer; Bytes: word);
    var SearchSeed: longint;
    implementation
    procedure Mark(Kind: word; P: pointer; Bytes: word);
    begin
      asm
        mov ax, Kind
        or ax, $f000
        les bx, P
        mov cx, bx
        mov bx, es
        mov dx, Bytes
        int $f0
      end;
    end;
    end.
    """,
        )
        write(
            target / "SIO.PAS",
            """unit SIO;
    {$G+,R-,S-,A+}
    interface
    function ReadKey: char;
    function KeyPressed: boolean;
    function InnerPolls(Count: word): word;
    procedure Delay(MS: word);
    procedure Sound(Hz: word);
    procedure NoSound;
    var PollsRemaining: longint;
    implementation
    function ReadKey: char; assembler;
    asm mov ax, $f010; int $f0 end;
    function HostPressed: boolean; assembler;
    asm mov ax, $f011; int $f0 end;
    function KeyPressed: boolean;
    begin
      if PollsRemaining > 0 then
      begin
        Dec(PollsRemaining);
        KeyPressed := false;
      end
      else KeyPressed := HostPressed;
    end;
    function InnerPolls(Count: word): word;
    begin
      if PollsRemaining >= Count then begin
        Dec(PollsRemaining, Count); InnerPolls := Count + 1;
      end else begin
        InnerPolls := PollsRemaining + 1; PollsRemaining := 0;
        if not HostPressed then Halt(95);
      end;
    end;
    procedure Delay(MS: word);
    begin end;
    procedure Sound(Hz: word);
    begin end;
    procedure NoSound;
    begin end;
    end.
    """,
        )
        p = target / "KBGFX.PAS"
        s = p.read_bytes().decode("cp866")
        interface = s[: s.lower().index("implementation")]
        decls = re.findall(r"^procedure[^\n]+;", interface, re.I | re.M)
        logical = ""
        if "procedure LocateViewportBuffer;" in s:
            a = s.index("procedure LocateViewportBuffer;")
            b = s.index("procedure ClearPicturePlanes(", a)
            logical = s[a:b]
        body = interface + "implementation\nuses SBridge, SIO;\n"
        for decl in decls:
            if "AdvanceNearbyRoamers" in decl or "RevealNearbyTiles" in decl:
                continue
            body += decl + "\nbegin\n"
            if "DrawText(" in decl:
                body += "  if PollsRemaining = 0 then begin\n    Mark(14, Ptr(X, Y), 0);\n    Mark(12, @Text, Length(Text) + 1);\n  end;\n"
            if "ClearRectangle(" in decl:
                body += "  Mark(13, Ptr(X1, Y1), 0);\n"
            body += "end;\n"
        write(p, body + logical + "end.\n")
        for p in target.glob("*"):
            if p.suffix not in (".PAS", ".INC"):
                continue
            if p.name in ("SBRIDGE.PAS", "CRT.PAS", "SIO.PAS", "KBGFX.PAS"):
                continue
            s = p.read_bytes().decode("cp866").replace("\r\n", "\n")
            if p.suffix == ".PAS" and "implementation" in s:
                pos = s.index("implementation") + len("implementation")
                m = re.search(r"\buses\s+", s[pos:])
                if m:
                    a = pos + m.end()
                    s = s[:a] + "SBridge, " + s[a:]
                else:
                    s = s[:pos] + "\nuses SBridge;\n" + s[pos:]
            s = re.sub(r"\bCrt\b", "SIO", s, flags=re.I)
            s = s.replace(
                "  PrepareCampaign(MenuChoice);",
                "  UseRandomSeed(SearchSeed);\n  PrepareCampaign(MenuChoice);",
            )
            prefix = "Game.Runtime." if name == "CUR" else "Game."
            campaign = "Game.Campaign." if name == "CUR" else "Game."
            s = s.replace(
                prefix + "ActionScratch := " + campaign + "MagicPower;",
                "Mark(1, nil, 0);\n  "
                + prefix
                + "ActionScratch := "
                + campaign
                + "MagicPower;",
            )
            if name == "CUR":
                if p.name == "KBBDRAW.PAS":
                    s = s.replace(
                        "begin\n  if Color < 15 then",
                        "begin\n  Mark(4, @Combat, SizeOf(Combat));\n  Mark(8, Ptr(X, Y), Color);\n  if Color < 15 then",
                    )
                if p.name == "KBBATTLE.PAS":
                    s = s.replace(
                        "Finished:\n  LoadResourceFile(",
                        "Finished:\n  Mark(9, nil, 0);\n  LoadResourceFile(",
                    )
                if p.name == "KBBMAGIC.PAS":
                    s = s.replace(
                        "  X := Combat.CursorX;",
                        "  Mark(18, nil, Spell);\n  X := Combat.CursorX;",
                    )
                    s = s.replace(
                        "    repeat\n      Game.Runtime.LastScan := ReadScanCode",
                        "    Mark(10, nil, 0);\n    repeat\n      Game.Runtime.LastScan := ReadScanCode",
                    )
            # Only batch empty keyboard polls. DOS verification keeps the original loop.
            s = s.replace(
                "for "
                + prefix
                + "IdleCounter := 1 to 200 do\n      if KeyPressed then goto InputReady\n      else Delay(2);",
                prefix
                + "IdleCounter := InnerPolls(200);\n    if "
                + prefix
                + "IdleCounter <= 200 then goto InputReady;",
            )
            # Function-entry markers are observation points, with no game state writes.
            for routine, kind in [("FirstSeriesEnding", 2), ("GameOver", 3)]:
                s = s.replace(
                    "procedure " + routine + ";\nbegin",
                    "procedure "
                    + routine
                    + ";\nbegin\n  Mark("
                    + str(kind)
                    + ", nil, 0);",
                )
            write(p, s)
        write(
            target / "SGHOST.PAS",
            """program SearchGame;
    {$G+,R-,S-,I+,A+}
    {$M 16384,0,655360}
    uses KBApp, KBRandom, KBState, KBTables, SBridge, SIO;
    var Seed: longint; Error: integer;
    begin
      Val(ParamStr(1), Seed, Error);
      if Error <> 0 then Halt(1);
      SearchSeed := Seed;
      UseRandomSeed(Seed);
      Mark(0, @Game, SizeOf(Game));
      Mark(5, @CreatureDefinitions, SizeOf(CreatureDefinitions));
      Mark(6, @RandSeed, 4);
      Mark(7, @PollsRemaining, 4);
      RunGame;
    end.
    """,
        )
    shutil.copytree(ROOT / "PASCAL", WORK / "PASCAL", dirs_exist_ok=True)

    source = WORK / "BASE/SRC"
    source.mkdir(parents=True, exist_ok=True)
    for p in (ROOT / "SRC").rglob("*"):
        rel = p.relative_to(ROOT / "SRC")
        if p.is_file() and (
            p.suffix.upper() in (".PAS", ".INC")
            or rel.parts[0] in ("ART", "DOC")
            or p.name == "PACK.LST"
        ):
            dest = source / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dest)
    for name in ("CUR", "REF", "DOSCUR", "DOSREF"):
        (WORK / name / "DATA").mkdir(parents=True, exist_ok=True)
    print(WORK)


if __name__ == "__main__":
    prepare()
