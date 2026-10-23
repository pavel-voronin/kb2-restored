"""Prepare an independent TP7/DOS replay with original drawing and game logic."""

import re, shutil
from prepare import ROOT, WORK, write
from state import Game, Battle
import ctypes

IO = r"""unit SIO;
{$G+,R-,S-,I+,A+}
interface
function ReadKey: char;
function ReadScanCode: byte;
function KeyPressed: boolean;
procedure Delay(MS: word);
procedure Sound(Hz: word);
procedure NoSound;
procedure Boundary(Kind: word);
var PollsRemaining: longint; InputCount: word;
implementation
uses Dos;
type TEvent = packed record Scan, Phase: byte; Polls: longint end;
var Events: file of TEvent; Next: TEvent; Loaded, InStep: boolean;
    Extended: byte;
procedure Load;
begin
  if not Loaded then begin
    if Eof(Events) then Halt(91);
    Read(Events, Next); Loaded := true;
  end;
end;
procedure Boundary(Kind: word);
begin
  InStep := Kind = 1;
  if InStep then begin
    Load;
    if Next.Phase <> 1 then Halt(92);
    PollsRemaining := Next.Polls;
  end;
end;
function TakeScan: byte;
begin
  Load;
  if (not InStep) and (Next.Phase = 1) then Halt(93);
  TakeScan := Next.Scan;
  Loaded := false; InStep := false; Inc(InputCount);
end;
function ReadScanCode: byte;
begin ReadScanCode := TakeScan end;
function ReadKey: char;
var Scan: byte;
begin
  if Extended <> 0 then begin
    ReadKey := Chr(Extended); Extended := 0; Exit;
  end;
  Scan := TakeScan;
  case Scan of
    1: ReadKey := #27;
    2..11: ReadKey := Chr(48 + ((Scan - 1) mod 10));
    14: ReadKey := #8;
    15: ReadKey := #9;
    21: ReadKey := 'y';
    28: ReadKey := #13;
    49: ReadKey := 'n';
    57: ReadKey := ' ';
  else ReadKey := #0; Extended := Scan;
  end;
end;
function KeyPressed: boolean;
begin
  if not InStep then begin KeyPressed := false; Exit end;
  if PollsRemaining > 0 then begin
    Dec(PollsRemaining); KeyPressed := false;
  end else KeyPressed := true;
end;
procedure Delay(MS: word); begin end;
procedure Sound(Hz: word); begin end;
procedure NoSound; begin end;
begin
  Assign(Events, 'INPUT.BIN'); Reset(Events);
end.
"""
BRIDGE = r"""unit SBridge;
{$G+,R-,S-,I+,A+}
interface
procedure Mark(Kind: word; P: pointer; Bytes: word);
var SearchSeed: longint;
implementation
uses SIO;
var States: file; GameP, RngP: pointer; InputIndex: word;
    OldExit: pointer; Victory: boolean; BattleP: pointer; Cells: file;
procedure Done; far;
var ResultFile: file; Code: word;
begin
  ExitProc := OldExit;
  Close(States); Close(Cells);
  Assign(ResultFile, 'RESULT.BIN'); Rewrite(ResultFile, 1);
  Code := ExitCode;
  BlockWrite(ResultFile, Victory, 1);
  BlockWrite(ResultFile, Code, 2);
  Close(ResultFile);
end;
procedure Mark(Kind: word; P: pointer; Bytes: word);
var CampaignP, FieldP: pointer; X, Y: word;
begin
  case Kind of
    0: GameP := P;
    6: RngP := P;
    4: BattleP := P;
    8: begin
      X := Seg(P^); Y := Ofs(P^);
      BlockWrite(Cells, SIO.InputCount, 2);
      BlockWrite(Cells, X, 2); BlockWrite(Cells, Y, 2);
      BlockWrite(Cells, Bytes, 2); BlockWrite(Cells, RngP^, 4);
      FieldP := Ptr(Seg(GameP^), Ofs(GameP^) + FIELD_OFFSET);
      BlockWrite(Cells, FieldP^, 90);
      BlockWrite(Cells, BattleP^, BATTLE_BYTES);
    end;
    1, 2, 3: begin
      BlockWrite(States, Kind, 2);
      CampaignP := Ptr(Seg(GameP^), Ofs(GameP^) + CAMPAIGN_OFFSET);
      BlockWrite(States, CampaignP^, 46816);
      BlockWrite(States, RngP^, 4);
      if Kind = 2 then Victory := true;
      SIO.Boundary(Kind);
    end;
  end;
end;
begin
  Assign(States, 'STATES.BIN'); Rewrite(States, 1);
  Assign(Cells, 'BCELLS.BIN'); Rewrite(Cells, 1);
  OldExit := ExitProc; ExitProc := @Done;
end.
"""


def prepare_native():
    for variant in ("CUR", "REF"):
        target = WORK / ("DOS" + variant) / "CODE"
        target.mkdir(parents=True, exist_ok=True)
        src = ROOT / "SRC" if variant == "CUR" else WORK / "REF/SRC"
        for p in src.iterdir():
            if p.suffix.upper() in (".PAS", ".INC"):
                shutil.copy2(p, target / p.name.upper())
        for p in target.iterdir():
            if p.suffix not in (".PAS", ".INC"):
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
            prefix = "Game.Runtime." if variant == "CUR" else "Game."
            campaign = "Game.Campaign." if variant == "CUR" else "Game."
            s = s.replace(
                prefix + "ActionScratch := " + campaign + "MagicPower;",
                "Mark(1, nil, 0);\n  "
                + prefix
                + "ActionScratch := "
                + campaign
                + "MagicPower;",
            )
            for routine, kind in [("FirstSeriesEnding", 2), ("GameOver", 3)]:
                s = s.replace(
                    "procedure " + routine + ";\nbegin",
                    "procedure "
                    + routine
                    + ";\nbegin\n  Mark("
                    + str(kind)
                    + ", nil, 0);",
                )
            if variant == "CUR" and p.name == "KBBDRAW.PAS":
                s = s.replace(
                    "begin\n  if Color < 15 then",
                    "begin\n  Mark(4, @Combat, SizeOf(Combat));\n  Mark(8, Ptr(X, Y), Color);\n  if Color < 15 then",
                )
            write(p, s)
        write(
            target / "SBRIDGE.PAS",
            BRIDGE.replace("CAMPAIGN_OFFSET", str(Game.Campaign.offset))
            .replace(
                "FIELD_OFFSET", str(dict(Game._fields_)["Runtime"].BattleField.offset)
            )
            .replace("BATTLE_BYTES", str(ctypes.sizeof(Battle))),
        )
        write(target / "SIO.PAS", IO)
        write(
            target / "KBINPUT.PAS",
            """unit KBInput;
    interface
    function ReadScanCode: byte;
    function BIOSKeyPressed: boolean;
    implementation
    uses SIO;
    function ReadScanCode: byte;
    begin ReadScanCode := SIO.ReadScanCode end;
    function BIOSKeyPressed: boolean;
    begin BIOSKeyPressed := true end;
    end.
    """,
        )
        shutil.copy2(WORK / variant / "CODE/SGHOST.PAS", target / "SGHOST.PAS")
        (target.parent / "DATA").mkdir(parents=True, exist_ok=True)


if __name__ == "__main__":
    prepare_native()
