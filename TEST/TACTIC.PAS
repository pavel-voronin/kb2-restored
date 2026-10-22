program TacticsRegression;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}

uses KBTypes, KBState, KBTables, KBStart, KBRandom, KBBType,
  KBBDmg, KBPlayer, KBBAI, KBArt, KBFiles, KBSess;

procedure RunBattleChecks(var Combat: TBattleState);
type
  PBytes = ^TBytes;
  TBytes = array[0..511] of byte;
var
  Report: file;
  TestLog: text;
  Checksum: longint;
  A, D, Pass, Strike, CellX, CellY, Slot, Mode: byte;
  X, Y: shortint;
  AX, AY: shortint;
  AttackerHP, DefenderHP: longint;
  Killed: word;
  Found: boolean;

procedure Put(var Value; Bytes: word);
var
  I, BitIndex: word;
begin
  BlockWrite(Report, Value, Bytes);
  for I := 0 to Bytes - 1 do
  begin
    Checksum := Checksum xor PBytes(@Value)^[I];
    for BitIndex := 1 to 8 do
      if Checksum and 1 <> 0 then
        Checksum := (Checksum shr 1) xor longint($EDB88320)
      else Checksum := Checksum shr 1;
  end;
end;

begin
  Checksum := -1;
  Assign(Report, 'TACTIC.BIN');
  Rewrite(Report, 1);
  for A := 25 to 29 do CreatureDefinitions[A] := CreatureDefinitions[A - 25];
  for Pass := 0 to 2 do
    for A := 0 to 29 do
      for D := 0 to 29 do
      begin
        FillChar(Combat, SizeOf(Combat), 0);
        Combat.VampireInitialCount := 100;
        UseRandomSeed(987654 + longint(Pass) * 10000 + A * 100 + D);
        Game.Campaign.WeeklySpecies := (A + D) mod 25;
        Game.Campaign.DamageBonus := D mod 3;
        AttackerHP := longint(CreatureDefinitions[A].Defense) * 20;
        DefenderHP := longint(CreatureDefinitions[D].Defense) * 30;
        for Strike := 1 to 6 do
        begin
          Killed := ResolveStrike(Combat, A, D, AttackerHP, DefenderHP);
          Put(Killed, SizeOf(Killed));
          Put(AttackerHP, SizeOf(AttackerHP));
          Put(DefenderHP, SizeOf(DefenderHP));
          Put(Combat.DemonHalved, 1);
          Put(Combat.DragonResists, 1);
          Put(Combat.DemonResists, 1);
          Put(Combat.MutantResists, SizeOf(Combat.MutantResists));
          Put(RandSeed, SizeOf(RandSeed));
        end;
      end;
  for CellX := 0 to 5 do
    for CellY := 0 to 4 do
      case (CellX + CellY) mod 3 of
        0: Game.Runtime.BattleField[CellX, CellY] := 112 + (CellX mod 5) * 3;
        1: Game.Runtime.BattleField[CellX, CellY] := 32 + (CellY mod 5) * 3;
        2: Game.Runtime.BattleField[CellX, CellY] := 0;
      end;
  for Mode := 0 to 1 do
    for AX := -1 to 6 do
      for AY := -1 to 5 do
      begin
        X := AX;
        Y := AY;
        if Mode = 0 then Found := FindAdjacent(X, Y, 31)
        else Found := FindAdjacent(X, Y, 111);
        Put(Found, 1);
        Put(X, 1);
        Put(Y, 1);
      end;
  for Slot := 0 to 4 do
    for Mode := 0 to 3 do
    begin
      FillChar(Combat, SizeOf(Combat), 0);
      FillChar(Game.Runtime.BattleField, SizeOf(Game.Runtime.BattleField), 0);
      for A := 0 to 9 do Combat.Player[A].Species := 100;
      Combat.PlayerCount := 1;
      Combat.Player[Slot].Species := 0;
      Combat.CanMove[Slot] := Mode mod 2 = 0;
      Combat.ReadyPlayerCount := Mode div 2;
      Game.Runtime.BattleField[0, Slot] := Slot * 3 + 112;
      Game.Runtime.CurrentBattleSlot := 0;
      NextPlayerUnit(Combat);
      Put(Game.Runtime.CurrentBattleSlot, 1);
      Put(Combat.CursorX, 1);
      Put(Combat.CursorY, 1);
      Put(Combat.ReadyPlayerCount, 1);
    end;
  for Mode := 0 to 5 do
  begin
    FillChar(Combat, SizeOf(Combat), 0);
    FillChar(Game.Runtime.BattleField, SizeOf(Game.Runtime.BattleField), 0);
    FillChar(Game.Runtime.BattleDistances, SizeOf(Game.Runtime.BattleDistances), 0);
    for A := 0 to 9 do
    begin
      Combat.Player[A].Species := 100;
      Combat.Enemy[A].Species := 100;
    end;
    A := Mode * 4;
    D := 2;
    Combat.PlayerCount := 1;
    Combat.EnemyCount := 1;
    Combat.FrozenEnemySlot := 100;
    Combat.EnemyPhaseFinished := true;
    Combat.RoundMagicReady := true;
    Combat.VampireInitialCount := 100;
    Combat.Player[0].Species := D;
    Combat.Player[0].Count := 20;
    Combat.Player[0].InitialCount := 20;
    Combat.Player[0].HitPoints := longint(CreatureDefinitions[D].Defense) * 20;
    Combat.Player[0].AttackPower := longint(CreatureDefinitions[D].Attack) * 20;
    Combat.Player[0].Shots := CreatureDefinitions[D].Flags and 31;
    Combat.Player[0].CanFly := CreatureDefinitions[D].Flags >= 128;
    Combat.Enemy[0].Species := A;
    Combat.Enemy[0].Count := 3;
    Combat.Enemy[0].InitialCount := 3;
    Combat.Enemy[0].HitPoints := longint(CreatureDefinitions[A].Defense) * 3;
    Combat.Enemy[0].AttackPower := longint(CreatureDefinitions[A].Attack) * 3;
    Combat.Enemy[0].Shots := CreatureDefinitions[A].Flags and 31;
    Combat.Enemy[0].CanFly := CreatureDefinitions[A].Flags >= 128;
    Combat.CanMove[0] := true;
    Game.Runtime.BattleResult := 0;
    Game.Runtime.CurrentBattleSlot := 0;
    Game.Runtime.BattleField[0, 0] := 112;
    Game.Runtime.BattleField[5, 4] := 32;
    Game.Runtime.BattleDistances[0, 0] := 20;
    Game.Runtime.BattleDistances[5, 4] := 3;
    Game.Campaign.WeeklySpecies := 24;
    Game.Campaign.DamageBonus := 0;
    LoadCreatureArt(D);
    CopyRecord(0, 0, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
    LoadCreatureArt(A);
    CopyRecord(0, 0, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[2]);
    UseRandomSeed(42000 + Mode);
    for Pass := 1 to 2 do
    begin
      if Game.Runtime.BattleResult = 0 then EnemyPhase(Combat);
      Put(Combat, SizeOf(Combat));
      Put(Game.Runtime.BattleField, SizeOf(Game.Runtime.BattleField));
      Put(Game.Runtime.BattleDistances, SizeOf(Game.Runtime.BattleDistances));
      Put(Game.Runtime.BattleResult, 1);
      Put(Game.Runtime.CurrentBattleSlot, 1);
      Put(RandSeed, SizeOf(RandSeed));
    end;
  end;
  Close(Report);
  Checksum := not Checksum;
  if Checksum <> longint($D081892F) then Halt(7);
  Assign(TestLog, 'TACTIC.LOG');
  Rewrite(TestLog);
  WriteLn(TestLog, 'PASS: 16200 strikes, 112 targets, 20 selections, 12 AI phases.');
  Close(TestLog);
  if ParamStr(1) <> '/KEEP' then Erase(Report);
end;

var
  Combat: TBattleState;
begin
  InitializeRuntime;
  SetGraphicsMode(1);
  LoadTitle;
  LoadGameArtwork;
  Game.Runtime.SoundDisabled := true;
  RunBattleChecks(Combat);
  SetGraphicsMode(0);
end.
