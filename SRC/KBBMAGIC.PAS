unit KBBMagic;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure RedrawLowerRows;
procedure SelectSpellTarget(var Combat: TBattleState; Spell: byte; ConsumeScroll: boolean);
procedure MagicMenu(var Combat: TBattleState);

implementation

uses KBState, KBTables, KBUI, KBGfx, KBInput, Crt, KBBDmg, KBBDraw;

procedure RedrawLowerRows;
var
  Y, X: byte;

begin
  for Y := 3 to 4 do
    for X := 0 to 5 do
      case Game.Runtime.BattleField[X, Y] of
        32..44, 112..124: begin
          DrawTile(BattleCellOffsets[Y * 6 + X], 0, Game.Runtime.BattleField[X, Y]);
          DrawCellCount(X, Y);
        end;
      else DrawPictureTile(BattleCellOffsets[Y * 6 + X], Game.Runtime.BattleField[X, Y]);
      end;
end;

procedure SelectSpellTarget(var Combat: TBattleState; Spell: byte; ConsumeScroll: boolean);
var
  X, Y: byte;

procedure TeleportUnit;
begin
  if Combat.TeleportSelected then
    case Game.Runtime.BattleField[X, Y] of
      112, 115, 118, 121, 124: begin
        HeaderPrompt(17);
        Combat.TeleportX := X;
        Combat.TeleportY := Y;
        Game.Runtime.LastScan := 48;
      end;
    else Game.Runtime.LastScan := 48;
    end
  else if Game.Runtime.BattleField[X, Y] = 0 then
    RelocateUnit(Combat.TeleportX, Combat.TeleportY, X, Y)
  else Game.Runtime.LastScan := 48;
end;

procedure MultiplyUnit;
var
  Slot: byte;

begin
  Slot := (Game.Runtime.BattleField[X, Y] - 112) div 3;
  Combat.Player[Slot].HitPoints := Game.Campaign.MagicPower * 30 + Combat.Player[Slot].HitPoints;
  Game.Runtime.BattleTextColumn := Combat.Player[Slot].HitPoints div
    CreatureDefinitions[Combat.Player[Slot].Species].Defense;
  if Combat.Player[Slot].HitPoints mod CreatureDefinitions[Combat.Player[Slot].Species].Defense > 0 then
    Inc(Game.Runtime.BattleTextColumn);
  Game.Runtime.BattleDistances[X, Y] := Game.Runtime.BattleTextColumn;
  Combat.Player[Slot].Count := Game.Runtime.BattleTextColumn;
  DrawCellCount(X, Y);
end;

procedure DamageUnit(Factor: byte);
var
  Slot: byte;

begin
  Slot := (Game.Runtime.BattleField[X, Y] - 32) div 3;
  AnimateImpact(X, Y);
  Game.Runtime.BattleTextColumn := ApplyDamage(Combat.Enemy[Slot].Species, Game.Campaign.MagicPower * Factor,
    Combat.Enemy[Slot].HitPoints);

  if Game.Runtime.BattleTextColumn > 0 then ReportEnemyLoss(Combat, Slot, X, Y);
end;

procedure ResurrectUnit;
var
  Slot: byte;
  NewHitPoints: longint;

begin
  Slot := (Game.Runtime.BattleField[X, Y] - 112) div 3;
  NewHitPoints := Game.Campaign.MagicPower * 50 + Combat.Player[Slot].HitPoints;
  Game.Runtime.BattleTextColumn := Game.Runtime.BattleDistances[X, Y] +
    NewHitPoints div CreatureDefinitions[Combat.Player[Slot].Species].Defense;
  if Combat.Player[Slot].InitialCount >= Game.Runtime.BattleTextColumn then
  begin
    Game.Runtime.BattleDistances[X, Y] := Game.Runtime.BattleTextColumn;
    Combat.Player[Slot].Count := Game.Runtime.BattleTextColumn;
    Combat.Player[Slot].HitPoints := NewHitPoints;
  end
  else
  begin
    Game.Runtime.BattleDistances[X, Y] := Combat.Player[Slot].InitialCount;
    Combat.Player[Slot].Count := Combat.Player[Slot].InitialCount;
    Combat.Player[Slot].HitPoints := CreatureDefinitions[Combat.Player[Slot].Species].Defense *
      Combat.Player[Slot].Count;
  end;

  DrawCellCount(X, Y);
end;

begin
  case Spell of
    7: if Combat.TeleportSelected then HeaderPrompt(17)
    else HeaderPrompt(16);
    8, 12: HeaderPrompt(16);
    9, 10, 11, 13: HeaderPrompt(20);
  end;

  if ConsumeScroll and (Game.Campaign.Scrolls[Spell] > 0) then Dec(Game.Campaign.Scrolls[Spell]);
  X := Combat.CursorX;
  Y := Combat.CursorY;

  repeat
    AwaitCellKey(Combat, X, Y, 15, 0);
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

      28: case Spell of
        7: begin
          Combat.TeleportSelected := not Combat.TeleportSelected;
          TeleportUnit
        end;

        8: case Game.Runtime.BattleField[X, Y] of 112, 115, 118, 121, 124: MultiplyUnit end;
        9: case Game.Runtime.BattleField[X, Y] of 32..44: DamageUnit(80) end;
        10: case Game.Runtime.BattleField[X, Y] of
          32..44: Combat.FrozenEnemySlot := (Game.Runtime.BattleField[X, Y] - 32) div 3;
        end;

        11: case Game.Runtime.BattleField[X, Y] of 32..44: DamageUnit(50) end;
        12: case Game.Runtime.BattleField[X, Y] of 112, 115, 118, 121, 124: ResurrectUnit end;
        13: case Game.Runtime.BattleField[X, Y] of
          32..44: Combat.Poison[(Game.Runtime.BattleField[X, Y] - 32) div 3] := 1;
        end;
      end;
    end;
  until (Game.Runtime.LastScan = 28) or (Game.Runtime.LastScan = 1);
  Combat.EnemyPhaseFinished := false;
end;

procedure MagicMenu(var Combat: TBattleState);

const
  MagicMenuCaption = '‚Ž‹˜…‘’‚Ž';
  TeleportMenuItem = '1) ’…‹…Ž’';
  MultiplyMenuItem = '2) €‡ŒŽ†…ˆ…';
  LightningMenuItem = '3) ˜€Ž‚€Ÿ ŒŽ‹ˆŸ';
  FreezeMenuItem = '4) ŒŽŽ‡';
  ClubMenuItem = '5) „“ˆŠ€';
  ResurrectMenuItem = '6) ‚Ž‘Š…˜…ˆ…';
  InfectionMenuItem = '7) ˆ”…Š–ˆŸ';

var
  I, X, Y: byte;

begin
  Combat.TeleportSelected := false;
  if Game.Campaign.MagicPower = 0 then HeaderPrompt(18)
  else
  begin
    DrawDialog(8, 230, 488, 320);
    HeaderPrompt(15);
    DrawText(false, 24, 240, MagicMenuCaption);
    DrawText(false, 2, 256, TeleportMenuItem);
    DrawText(false, 2, 264, MultiplyMenuItem);
    DrawText(false, 2, 272, LightningMenuItem);
    DrawText(false, 2, 280, FreezeMenuItem);
    DrawText(false, 2, 288, ClubMenuItem);
    DrawText(false, 2, 296, ResurrectMenuItem);
    DrawText(false, 2, 304, InfectionMenuItem);

    for I := 7 to 13 do
    begin
      Str(Game.Campaign.Scrolls[I]: 3, Game.Runtime.TextBuffer);
      X := 21;
      Y := (I - 7) * 8;
      DrawText(false, X, Y + 256, Game.Runtime.TextBuffer);
    end;

    repeat
      Game.Runtime.LastScan := ReadScanCode
    until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan in [2..8]);

    if Game.Runtime.LastScan <> 1 then
    begin
      RedrawLowerRows;

      case Game.Runtime.LastScan of
        2: if Game.Campaign.Scrolls[7] > 0 then SelectSpellTarget(Combat, 7, true)
          else ShowNotice(0);
        3: if Game.Campaign.Scrolls[8] > 0 then SelectSpellTarget(Combat, 8, true)
          else ShowNotice(0);
        4: if Game.Campaign.Scrolls[9] > 0 then SelectSpellTarget(Combat, 9, true)
          else ShowNotice(0);
        5: if Game.Campaign.Scrolls[10] > 0 then SelectSpellTarget(Combat, 10, true)
          else ShowNotice(0);
        6: if Game.Campaign.Scrolls[11] > 0 then SelectSpellTarget(Combat, 11, true)
          else ShowNotice(0);
        7: if Game.Campaign.Scrolls[12] > 0 then SelectSpellTarget(Combat, 12, true)
          else ShowNotice(0);
        8: if Game.Campaign.Scrolls[13] > 0 then SelectSpellTarget(Combat, 13, true)
          else ShowNotice(0);
      end;
    end;

    RedrawLowerRows;
    HeaderPrompt(0);
  end;
end;

end.
