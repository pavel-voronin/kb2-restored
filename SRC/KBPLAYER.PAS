unit KBPlayer;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure NextPlayerUnit(var Combat: TBattleState);
function FindAdjacent(var X, Y: shortint; Base: byte): boolean;
procedure ShootUnit(var Combat: TBattleState; var Shots: byte; Slot: byte);
procedure MovePlayerUnit(var Combat: TBattleState; Slot: byte);

implementation

uses KBState, KBTables, Crt, KBBDmg, KBBDraw;

procedure NextPlayerUnit(var Combat: TBattleState);
var
  First: byte;

begin
  if Combat.ReadyPlayerCount < Combat.PlayerCount then
  begin
    if Game.Runtime.CurrentBattleSlot > 3 then Game.Runtime.CurrentBattleSlot := 0
    else Inc(Game.Runtime.CurrentBattleSlot);
    First := Game.Runtime.CurrentBattleSlot;

    while (Combat.Player[Game.Runtime.CurrentBattleSlot].Species = 100) or
      not Combat.CanMove[Game.Runtime.CurrentBattleSlot] do
    begin
      if Game.Runtime.CurrentBattleSlot > 3 then Game.Runtime.CurrentBattleSlot := 0
      else Inc(Game.Runtime.CurrentBattleSlot);

      if First = Game.Runtime.CurrentBattleSlot then
      begin
        Combat.ReadyPlayerCount := Combat.PlayerCount;
        Exit;
      end;
    end;

    FindUnitCell(Game.Runtime.CurrentBattleSlot, 112, Combat.CursorX, Combat.CursorY);
  end;
end;

function FindAdjacent(var X, Y: shortint; Base: byte): boolean;
label
  Found;

var
  DX, DY, TX, TY: shortint;

begin
  for DY := -1 to 1 do
    for DX := -1 to 1 do
    begin
      TX := X + DX;
      TY := Y + DY;

      if ((DX <> 0) or (DY <> 0)) and
        (TX >= 0) and (TX <= 5) and (TY >= 0) and (TY <= 4) and
        (Game.Runtime.BattleField[TX, TY] > Base) and
        (Game.Runtime.BattleField[TX, TY] < Base + 14) then goto Found;
    end;

  FindAdjacent := false;
  Exit;
Found:
  X := X + DX;
  Y := Y + DY;
  FindAdjacent := true;
end;

procedure ShootUnit(var Combat: TBattleState; var Shots: byte; Slot: byte);
var
  X, Y: shortint;

begin
  X := Combat.CursorX;
  Y := Combat.CursorY;

  if FindAdjacent(X, Y, 31) then Exit;
  Dec(Shots);
  Inc(Combat.ReadyPlayerCount);

  repeat
    AwaitCellKey(Combat, X, Y, 12, 0);
    case Game.Runtime.LastScan of
      71: if (X > 0) and (Y > 0) then
      begin
        Dec(X);
        Dec(Y)
      end;

      72: if Y > 0 then Dec(Y);
      73: if (X < 5) and (Y > 0) then
      begin
        Inc(X);
        Dec(Y)
      end;

      75: if X > 0 then Dec(X);
      77: if X < 5 then Inc(X);
      79: if (X > 0) and (Y < 4) then
      begin
        Dec(X);
        Inc(Y)
      end;

      80: if Y < 4 then Inc(Y);
      81: if (X < 5) and (Y < 4) then
      begin
        Inc(X);
        Inc(Y)
      end;

      28: if (Game.Runtime.BattleField[X, Y] >= 32) and (Game.Runtime.BattleField[X, Y] < 45) then
        AttackUnit(Combat, Combat.CursorX, Combat.CursorY, X, Y)
      else
        case Game.Runtime.BattleField[X, Y] of
          112, 115, 118, 121, 124: begin
            Combat.TargetSlot := (Game.Runtime.BattleField[X, Y] - 112) div 3;

            if Combat.Uncontrolled[Combat.TargetSlot] then AttackUnit(Combat, Combat.CursorX, Combat.CursorY, X, Y);
          end;
        else Game.Runtime.LastScan := 48;
        end;
    end;
  until Game.Runtime.LastScan = 28;
  Combat.CanMove[Slot] := false;
end;

procedure MovePlayerUnit(var Combat: TBattleState; Slot: byte);
var
  Movement: byte;

begin
  Movement := CreatureDefinitions[Combat.Player[Slot].Species].Movement;
  Inc(Combat.ReadyPlayerCount);

  repeat
    AwaitCellKey(Combat, Combat.CursorX, Combat.CursorY, 14, Movement);
    Combat.Cell := Combat.CursorX;
    Combat.TargetY := Combat.CursorY;

    case Game.Runtime.LastScan of
      31: if Combat.Player[Slot].Shots > 0 then
      begin
        Movement := Combat.ReadyPlayerCount;
        ShootUnit(Combat, Combat.Player[Slot].Shots, Slot);
        Combat.ReadyPlayerCount := Movement;
        Movement := 0;
      end;

      71: if (Combat.CursorX > 0) and (Combat.CursorY > 0) then
      begin
        Dec(Combat.Cell);
        Dec(Combat.TargetY);
      end;

      72: if Combat.CursorY > 0 then Dec(Combat.TargetY);
      73: if (Combat.CursorX < 5) and (Combat.CursorY > 0) then
      begin
        Inc(Combat.Cell);
        Dec(Combat.TargetY);
      end;

      75: if Combat.CursorX > 0 then Dec(Combat.Cell);
      77: if Combat.CursorX < 5 then Inc(Combat.Cell);
      79: if (Combat.CursorX > 0) and (Combat.CursorY < 4) then
      begin
        Dec(Combat.Cell);
        Inc(Combat.TargetY);
      end;

      80: if Combat.CursorY < 4 then Inc(Combat.TargetY);
      81: if (Combat.CursorX < 5) and (Combat.CursorY < 4) then
      begin
        Inc(Combat.Cell);
        Inc(Combat.TargetY);
      end;
    end;

    if Game.Runtime.LastScan in [71..81] then
      case Game.Runtime.BattleField[Combat.Cell, Combat.TargetY] of
        0: begin
          RelocateUnit(Combat.CursorX, Combat.CursorY, Combat.Cell, Combat.TargetY);
          Dec(Movement);
        end;

        32..44: begin
          AttackUnit(Combat, Combat.CursorX, Combat.CursorY, Combat.Cell, Combat.TargetY);
          if Game.Runtime.BattleDistances[Combat.Cell, Combat.TargetY] > 0 then
          begin
            Combat.TargetSlot := (Game.Runtime.BattleField[Combat.Cell, Combat.TargetY] - 32) div 3;

            if Combat.Retaliations[Combat.TargetSlot] > 0 then
            begin
              AttackUnit(Combat, Combat.Cell, Combat.TargetY, Combat.CursorX, Combat.CursorY);
              Dec(Combat.Retaliations[Combat.TargetSlot]);
            end;
          end;

          Movement := 0;
        end;

        112, 115, 118, 121, 124: begin
          Combat.TargetSlot := (Game.Runtime.BattleField[Combat.Cell, Combat.TargetY] - 112) div 3;
          if Combat.Uncontrolled[Combat.TargetSlot] then
          begin
            AttackUnit(Combat, Combat.CursorX, Combat.CursorY, Combat.Cell, Combat.TargetY);

            if Game.Runtime.BattleDistances[Combat.Cell, Combat.TargetY] > 0 then
            begin
              AttackUnit(Combat, Combat.Cell, Combat.TargetY, Combat.CursorX, Combat.CursorY);
              Dec(Combat.Retaliations[Combat.TargetSlot]);
            end;
          end;

          Movement := 0;
        end;
      end;
  until (Game.Runtime.LastScan in [1, 57]) or (Movement = 0);
  Combat.CanMove[Slot] := false;
end;

end.
