unit KBBDmg;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure AnimateImpact(X, Y: byte);
procedure RelocateUnit(var X, Y: byte; NewX, NewY: byte);
function ApplyDamage(Species: byte; Damage: longint; var HitPoints: longint): word;
function ResolveStrike(var Combat: TBattleState; Attacker, Defender: byte; var AttackerHitPoints,
    DefenderHitPoints: longint): word;
procedure ReportEnemyLoss(var Combat: TBattleState; Slot, X, Y: byte);
procedure AttackUnit(var Combat: TBattleState; AttackerX, AttackerY, DefenderX, DefenderY: byte);

implementation

uses KBState, KBTables, KBGfx, KBSound, Crt, KBBDraw;

procedure AnimateImpact(X, Y: byte);
begin
  PlayCue(6);
  DrawMaskedTile(BattleCellOffsets[Y * 6 + X], Game.Runtime.BattleField[X, Y], 1);
  Delay(100);
  DrawMaskedTile(BattleCellOffsets[Y * 6 + X], Game.Runtime.BattleField[X, Y], 2);
  Delay(100);
  DrawMaskedTile(BattleCellOffsets[Y * 6 + X], Game.Runtime.BattleField[X, Y], 4);
  Delay(100);
  DrawMaskedTile(BattleCellOffsets[Y * 6 + X], Game.Runtime.BattleField[X, Y], 8);
  Delay(100);
  DrawTile(BattleCellOffsets[Y * 6 + X], 0, Game.Runtime.BattleField[X, Y]);
end;

procedure RemoveFallenUnit(X, Y: byte);
var
  I, DeltaOffset, DeltaX, StopX, Steps: shortint;
  Destination: word;

begin
  Destination := BattleCellOffsets[Y * 6 + X];
  if X > 2 then
  begin
    DeltaOffset := -4;
    DeltaX := -1;
    Steps := X * 3;
    StopX := -1;
  end
  else
  begin
    DeltaOffset := 4;
    DeltaX := 1;
    Steps := (5 - X) * 3;
    StopX := 6;
  end;

  for I := 1 to Steps do
  begin
    DrawMaskedTile(Destination, Game.Runtime.BattleField[X, Y], 1);
    DrawMaskedTile(Destination, Game.Runtime.BattleField[X, Y], 2);
    DrawMaskedTile(Destination, Game.Runtime.BattleField[X, Y], 4);
    DrawMaskedTile(Destination, Game.Runtime.BattleField[X, Y], 8);
    Destination := Destination + DeltaOffset;
    Sound(I * 10);
  end;

  NoSound;
  Game.Runtime.BattleDistances[X, Y] := 0;
  Game.Runtime.BattleField[X, Y] := 0;
  I := X;

  repeat
    case Game.Runtime.BattleField[I, Y] of
      0, 48, 64, 80: DrawPictureTile(BattleCellOffsets[I + Y * 6], Game.Runtime.BattleField[I, Y]);
    else
    begin
      DrawTile(BattleCellOffsets[I + Y * 6], 0, Game.Runtime.BattleField[I, Y]);
      DrawCellCount(I, Y);
    end;
    end;

    I := I + DeltaX;
  until I = StopX;
end;

procedure ShowHalved(X, Y: byte);

const
  HalvedCaption = #143#142#143#142#139#128#140;

var
  TextX: byte;
  TextY: word;

begin
  TextY := BattleCellOffsets[Y * 6 + X] div 80;
  TextX := BattleCellOffsets[Y * 6 + X] - TextY * 80;
  Inc(TextX, 3);
  Inc(TextY, 32);
  DrawText(true, TextX, TextY, HalvedCaption);
  Delay(400);
  DrawTile(BattleCellOffsets[Y * 6 + X], 0, Game.Runtime.BattleField[X, Y]);
end;

procedure RelocateUnit(var X, Y: byte; NewX, NewY: byte);
begin
  DrawPictureTile(BattleCellOffsets[X + Y * 6], 0);
  Game.Runtime.BattleDistances[NewX, NewY] := Game.Runtime.BattleDistances[X, Y];
  Game.Runtime.BattleField[NewX, NewY] := Game.Runtime.BattleField[X, Y];
  DrawTile(BattleCellOffsets[NewX + NewY * 6], 0, Game.Runtime.BattleField[NewX, NewY]);

  if Game.Runtime.BattleField[NewX, NewY] > 0 then DrawCellCount(NewX, NewY);
  if (X <> NewX) or (Y <> NewY) then
  begin
    Game.Runtime.BattleField[X, Y] := 0;
    Game.Runtime.BattleDistances[X, Y] := 0;
  end;

  X := NewX;
  Y := NewY;
end;

function ApplyDamage(Species: byte; Damage: longint; var HitPoints: longint): word;
var
  Killed: word;
  Remaining: longint;

begin
  if HitPoints > Damage then
  begin
    Remaining := HitPoints - Damage;
    Killed := HitPoints div CreatureDefinitions[Species].Defense -
      Remaining div CreatureDefinitions[Species].Defense;
    if (HitPoints mod CreatureDefinitions[Species].Defense = 0) and (Killed > 0) and
       (Remaining mod CreatureDefinitions[Species].Defense > 0) then
      ApplyDamage := Killed - 1
      else ApplyDamage := Killed;
    HitPoints := Remaining;
  end
  else
  begin
    HitPoints := 0;
    ApplyDamage := 65535;
  end;
end;

function ResolveStrike(var Combat: TBattleState; Attacker, Defender: byte; var AttackerHitPoints,
    DefenderHitPoints: longint): word;
var
  Count: word;
  Temporary, Damage: longint;

begin
  Count := AttackerHitPoints div CreatureDefinitions[Attacker].Defense;
  if AttackerHitPoints mod CreatureDefinitions[Attacker].Defense > 0 then Inc(Count);
  Damage := CreatureDefinitions[Attacker].Attack;
  Temporary := CreatureDefinitions[Defender].Defense;

  if Attacker = Game.Campaign.WeeklySpecies then Damage := Game.Campaign.DamageBonus + Damage * Count
  else Damage := Game.Campaign.DamageBonus + (Random(Damage * Count * 2 div 3) + Damage * Count div 3);
  case Attacker of
    12: Inc(AttackerHitPoints, Damage);
    15: if not (Defender in [19, 22, 23]) then
    begin
      Temporary := Temporary * Count;

      if Damage < Temporary then Damage := Temporary;
    end;

    17: if Defender <> 19 then
    begin
      Temporary := AttackerHitPoints + Damage;
      Count := Temporary div CreatureDefinitions[17].Defense;

      if Count > Combat.VampireInitialCount then
      begin
        Temporary := CreatureDefinitions[17].Defense;
        AttackerHitPoints := Combat.VampireInitialCount * Temporary;
      end
      else AttackerHitPoints := Temporary;
    end;

    19: if CreatureDefinitions[Defender].Defense > Damage then
      Damage := CreatureDefinitions[Defender].Defense;
    21: begin
      Damage := CreatureDefinitions[Attacker].Attack;
      Damage := Damage * Count;
    end;

    22: begin
      Count := Random(10);
      if Count > 5 then
        if DefenderHitPoints shr 1 > Damage then
        begin
          Damage := DefenderHitPoints shr 1;
          Combat.DemonHalved := true;
        end;
    end;

    23: Damage := Damage * 3;
  end;

  case Defender of
    23: if Combat.DragonResists < 6 then
    begin
      Damage := 0;
      Inc(Combat.DragonResists);
    end;

    24: if Combat.DemonResists < 4 then
    begin
      Damage := 0;
      Inc(Combat.DemonResists);
    end;

    25..29: if Combat.MutantResists[Defender] < 4 then
    begin
      Damage := 0;
      Inc(Combat.MutantResists[Defender]);
    end;
  end;

  ResolveStrike := ApplyDamage(Defender, Damage, DefenderHitPoints);
end;

procedure ReportEnemyLoss(var Combat: TBattleState; Slot, X, Y: byte);
begin
  if Game.Runtime.BattleDistances[X, Y] <= Game.Runtime.BattleTextColumn then
  begin
    RemoveFallenUnit(X, Y);
    Combat.Enemy[Slot].Species := 100;
    Dec(Combat.EnemyCount);
    DrawPictureTile(BattleCellOffsets[Y * 6 + X], 0);

    if Combat.EnemyCount = 0 then Game.Runtime.BattleResult := 1;
  end
  else
  begin
    Game.Runtime.BattleDistances[X, Y] := Game.Runtime.BattleDistances[X, Y] - Game.Runtime.BattleTextColumn;
    Combat.Enemy[Slot].Count := Combat.Enemy[Slot].Count - Game.Runtime.BattleTextColumn;
    Combat.Enemy[Slot].AttackPower := CreatureDefinitions[Combat.Enemy[Slot].Species].Attack *
      Game.Runtime.BattleDistances[X, Y];
    DrawTile(BattleCellOffsets[X + Y * 6], 0, Game.Runtime.BattleField[X, Y]);
    DrawCellCount(X, Y);
  end;
end;

procedure AttackUnit(var Combat: TBattleState; AttackerX, AttackerY, DefenderX, DefenderY: byte);
var
  Attacker, Defender: TCombatUnit;
  OldHitPoints: longint;
  Killed: word;
  DefenderSlot, AttackerSlot: byte;
  DefenderIsPlayer, AttackerIsPlayer: boolean;
begin
  AnimateImpact(DefenderX, DefenderY);

  if Game.Runtime.BattleField[AttackerX, AttackerY] > 111 then
  begin
    AttackerSlot := (Game.Runtime.BattleField[AttackerX, AttackerY] - 112) div 3;
    Attacker := Combat.Player[AttackerSlot];
    AttackerIsPlayer := true;
  end
  else
  begin
    AttackerSlot := (Game.Runtime.BattleField[AttackerX, AttackerY] - 32) div 3;
    Attacker := Combat.Enemy[AttackerSlot];
    AttackerIsPlayer := false;
  end;

  if Game.Runtime.BattleField[DefenderX, DefenderY] > 111 then
  begin
    DefenderSlot := (Game.Runtime.BattleField[DefenderX, DefenderY] - 112) div 3;
    Defender := Combat.Player[DefenderSlot];
    DefenderIsPlayer := true;
  end
  else
  begin
    DefenderSlot := (Game.Runtime.BattleField[DefenderX, DefenderY] - 32) div 3;
    Defender := Combat.Enemy[DefenderSlot];
    DefenderIsPlayer := false;
  end;

  OldHitPoints := Attacker.HitPoints;
  Combat.VampireInitialCount := Attacker.InitialCount;
  Killed := ResolveStrike(Combat, Attacker.Species, Defender.Species, Attacker.HitPoints, Defender.HitPoints);

  if Combat.DemonHalved then
  begin
    ShowHalved(DefenderX, DefenderY);
    Combat.DemonHalved := false;
  end;

  if OldHitPoints < Attacker.HitPoints then
  begin
    Attacker.Count := Attacker.HitPoints div CreatureDefinitions[Attacker.Species].Defense;
    Game.Runtime.BattleDistances[AttackerX, AttackerY] := Attacker.Count;
    DrawCellCount(AttackerX, AttackerY);
  end;

  if Killed > 0 then
  begin
    if Killed >= Defender.Count then
    begin
      if Game.Runtime.BattleField[DefenderX, DefenderY] > 111 then
      begin
        Dec(Combat.PlayerCount);
        Dec(Combat.ReadyPlayerCount);

        if Combat.PlayerCount = 0 then Game.Runtime.BattleResult := 2;
      end
      else
      begin
        Dec(Combat.EnemyCount);

        if Combat.EnemyCount = 0 then Game.Runtime.BattleResult := 1;
      end;

      Defender.Species := 100;
      RemoveFallenUnit(DefenderX, DefenderY);
    end
    else
    begin
      Defender.Count := Defender.Count - Killed;
      Game.Runtime.BattleDistances[DefenderX, DefenderY] := Defender.Count;
      Defender.AttackPower := CreatureDefinitions[Defender.Species].Attack * Defender.Count;
    end;
  end;

  if Game.Runtime.BattleResult < 1 then
  begin
    DrawTile(BattleCellOffsets[DefenderX + DefenderY * 6], 0, Game.Runtime.BattleField[DefenderX, DefenderY]);
    DrawCellCount(DefenderX, DefenderY);
  end;

  if AttackerIsPlayer then Combat.Player[AttackerSlot] := Attacker
  else Combat.Enemy[AttackerSlot] := Attacker;
  if DefenderIsPlayer then Combat.Player[DefenderSlot] := Defender
  else Combat.Enemy[DefenderSlot] := Defender;
end;

end.
