unit KBBDraw;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure DrawCellCount(X, Y: byte);
procedure PulseCell(X, Y, Color: byte);
procedure HighlightCell(X, Y: byte);
procedure FindUnitCell(Side, Slot: byte; var X, Y: byte);
procedure AwaitCellKey(var Combat: TBattleState; X, Y, Color, Movement: byte);

implementation

uses KBState, KBTables, KBUI, KBGfx, KBInput, Crt;

procedure DrawCellCount(X, Y: byte);
begin
  if Game.Runtime.BattleDistances[X, Y] > 0 then
  begin
    Str(Game.Runtime.BattleDistances[X, Y], Game.Runtime.TextBuffer);
    Game.Runtime.BattleTextColumn := Length(Game.Runtime.TextBuffer);
    Game.Runtime.BattleTextColumn := 5 - Game.Runtime.BattleTextColumn + 8 + X * 12;
    Game.World.GenerationLimit := Y * 60 + 74;
    DrawText(false, Lo(Game.Runtime.BattleTextColumn), Game.World.GenerationLimit, Game.Runtime.TextBuffer);
  end;
end;

procedure PulseCell(X, Y, Color: byte);
var
  I, XPixel, YPixel: word;

procedure PaintCorners(Color: byte);
begin
  DrawLine(XPixel, YPixel, XPixel + 15, YPixel, Color);
  DrawLine(XPixel, YPixel + 1, XPixel + 15, YPixel + 1, Color);
  DrawLine(XPixel, YPixel, XPixel, YPixel + 10, Color);
  DrawLine(XPixel - 1, YPixel, XPixel - 1, YPixel + 10, Color);
  DrawLine(XPixel + 1, YPixel, XPixel + 1, YPixel + 10, Color);
  DrawLine(XPixel + 60, YPixel, XPixel + 75, YPixel, Color);
  DrawLine(XPixel + 60, YPixel + 1, XPixel + 75, YPixel + 1, Color);
  DrawLine(XPixel + 75, YPixel, XPixel + 75, YPixel + 10, Color);
  DrawLine(XPixel + 74, YPixel, XPixel + 74, YPixel + 10, Color);
  DrawLine(XPixel + 76, YPixel, XPixel + 76, YPixel + 10, Color);
  DrawLine(XPixel, YPixel + 49, XPixel + 15, YPixel + 49, Color);
  DrawLine(XPixel, YPixel + 50, XPixel + 15, YPixel + 50, Color);
  DrawLine(XPixel, YPixel + 40, XPixel, YPixel + 50, Color);
  DrawLine(XPixel - 1, YPixel + 40, XPixel - 1, YPixel + 50, Color);
  DrawLine(XPixel + 1, YPixel + 40, XPixel + 1, YPixel + 50, Color);
  DrawLine(XPixel + 60, YPixel + 49, XPixel + 75, YPixel + 49, Color);
  DrawLine(XPixel + 60, YPixel + 50, XPixel + 75, YPixel + 50, Color);
  DrawLine(XPixel + 75, YPixel + 40, XPixel + 75, YPixel + 50, Color);
  DrawLine(XPixel + 74, YPixel + 40, XPixel + 74, YPixel + 50, Color);
  DrawLine(XPixel + 76, YPixel + 40, XPixel + 76, YPixel + 50, Color);
end;

begin
  XPixel := X * 96 + 18;
  YPixel := Y * 60 + 23;
  PaintCorners(Color);

  for I := 0 to 60 do
  begin
    if BIOSKeyPressed then Exit
    else Delay(2);
  end;

  PaintCorners(2);
  for I := 0 to 60 do
  begin
    if BIOSKeyPressed then Exit
    else Delay(2);
  end;
end;

procedure HighlightCell(X, Y: byte);
var
  I: byte;

begin
  for I := 1 to 2 do PulseCell(X, Y, 5);
  DrawTile(BattleCellOffsets[X + Y * 6], 0, Game.Runtime.BattleField[X, Y]);
  DrawCellCount(X, Y);
end;

procedure FindUnitCell(Side, Slot: byte; var X, Y: byte);
begin
  Side := Side * 3 + Slot;
  X := 0;
  Y := 0;

  repeat
    repeat
      if Game.Runtime.BattleField[X, Y] = Side then Exit
      else Inc(Y);
    until Y > 4;
    Inc(X);
    Y := 0;
  until false;
end;

procedure AwaitCellKey(var Combat: TBattleState; X, Y, Color, Movement: byte);

const
  MovementCaption = '  '#132#162#168#166#165#173#168#165'(M):';
  ShotsCaption = ' / '#147#164#160'p(S):';
  FlightCaption = ' / '#147#172#165#165#226' '#171#165#226#160#226#236'(F)';
  UncontrolledCaption = 'Воины вышли из под контpоля.';
  AlreadyMovedCaption = #130#174#168#173#235' '#227#166#165' '#229#174#164#168#171#168'.';

var
  Slot: byte;
  Number: string[3];
  Status: string[70];

begin
  if Color < 15 then
  begin
    if Game.Runtime.BattleField[X, Y] > 111 then
    begin
      Slot := (Game.Runtime.BattleField[X, Y] - 112) div 3;
      ClearRectangle(16, 8, 607, 15);

      if Combat.CanMove[Slot] then
      begin
        if Color = 0 then Str(CreatureDefinitions[Combat.Player[Slot].Species].Movement, Number)
        else Str(Movement, Number);
        Status := CreatureDefinitions[Combat.Player[Slot].Species].Name + MovementCaption + Number;

        if Combat.Player[Slot].Shots > 0 then
        begin
          Str(Combat.Player[Slot].Shots, Number);
          Status := Status + ShotsCaption + Number;
        end;

        if Combat.Player[Slot].CanFly then Status := Status + FlightCaption;
        DrawText(false, 2, 8, Status);
      end
      else
        if Combat.Uncontrolled[Slot] then DrawText(false, 2, 8, UncontrolledCaption)
        else DrawText(false, 2, 8, AlreadyMovedCaption);
    end
    else
      if Color = 12 then HeaderPrompt(20)
      else HeaderPrompt(25);
  end;

  repeat
    PulseCell(X, Y, Color)
  until BIOSKeyPressed;

  case Game.Runtime.BattleField[X, Y] of
    0, 48, 64, 80: DrawPictureTile(BattleCellOffsets[X + Y * 6], Game.Runtime.BattleField[X, Y]);
  else
  begin
    DrawTile(BattleCellOffsets[X + Y * 6], 0, Game.Runtime.BattleField[X, Y]);
    DrawCellCount(X, Y);
  end;
  end;

  Game.Runtime.LastScan := ReadScanCode;
end;

end.
