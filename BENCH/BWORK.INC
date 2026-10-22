procedure RunBenchmarks;
const
  CampaignBytes = 46816;
{$IFDEF BCOUNT}
  Samples = 1;
{$ELSE}
  Samples = 5;
{$ENDIF}
type
  TCampaignCopy = array[0..CampaignBytes - 1] of byte;
  PCampaignCopy = ^TCampaignCopy;
  TResult = packed record
    Killed: word;
    AttackerHP, DefenderHP: longint;
    Halved, Dragon, Demon: byte;
    Mutants: array[0..4] of byte;
    Seed: longint;
  end;
  TResultArray = array[0..2699] of TResult;
  PResultArray = ^TResultArray;
var
  Output: text;
  Snapshot: PCampaignCopy;
  Results: PResultArray;
  FirstTick, Elapsed, Hash: longint;
  Level, Sample, Pass, A, D, Strike, Repeats: byte;
  Row, RepeatIndex, Mode: word;
  X, Y, AX, AY: shortint;
  Found: boolean;
  AttackerHP, DefenderHP: longint;
  Killed: word;
  InitialHeap: longint;

procedure Put(var Value; Bytes: word);
begin
  Hash := (Hash shl 1) xor (Hash shr 31) xor Digest(Value, Bytes);
end;

procedure RunEnemyPhase;
begin
  Counting := true;
  FirstTick := ClockTicks;
  EnemyPhase(Combat);
  Inc(Elapsed, ClockTicks - FirstTick);
  Counting := false;
end;

procedure RecordResult(Name: string; Sample: word; Ticks, Hash: longint);
var
  I: byte;
begin
  Write(Output, Name, ',', Sample, ',', Ticks, ',', Hash);
  for I := 1 to CounterCount do Write(Output, ',', Counts[I]);
  WriteLn(Output);
  Close(Output);
{$IFDEF BREF}
{$IFDEF BCOUNT}
  Assign(Output, 'REFCNT.CSV');
{$ELSE}
  Assign(Output, 'REFTIME.CSV');
{$ENDIF}
{$ELSE}
{$IFDEF BCOUNT}
  Assign(Output, 'CURCNT.CSV');
{$ELSE}
  Assign(Output, 'CURTIME.CSV');
{$ENDIF}
{$ENDIF}
  Append(Output);
end;

begin
  if EGAMemoryKB <> 256 then
  begin
    asm mov ax, 3; int 10h end;
    WriteLn('Benchmark requires 256 KB EGA. Set vmemsize=0 and vmemsizekb=256.');
    Halt(1);
  end;
  Repeats := Samples;
  if (Samples > 3) and (ParamStr(1) = '/LOW') then Repeats := 3;
  if ParamStr(1) = '/QUICK' then Repeats := 1;
{$IFDEF BREF}
{$IFDEF BCOUNT}
  Assign(Output, 'REFCNT.CSV');
{$ELSE}
  Assign(Output, 'REFTIME.CSV');
{$ENDIF}
{$ELSE}
{$IFDEF BCOUNT}
  Assign(Output, 'CURCNT.CSV');
{$ELSE}
  Assign(Output, 'CURTIME.CSV');
{$ENDIF}
{$ENDIF}
  Rewrite(Output);
  WriteLn(Output, 'case,sample,pit_ticks,hash,strikes,damage,targets,target_cells,',
    'cost_cells,frame_calls,frame_cells,random,tiles,copy_bytes,enemy_phases');
  WriteLn(Output, 'memory,0,', SizeOf(Game), ',', HeapRequested, ',', HeapActual, ',', HeapPeak,
    ',', AllocationCount, ',', MemAvail, ',', MaxAvail, ',0,0,0,0,0,0');
  StartClock;
  InitialHeap := MemAvail;
  GetMem(Snapshot, CampaignBytes);
  Move(Game.Campaign.Flags.Discovery, Snapshot^, CampaignBytes);
  for Level := 0 to 3 do
    for Sample := 1 to Repeats do
    begin
      Move(Snapshot^, Game.Campaign.Flags.Discovery, CampaignBytes);
      UseRandomSeed(12345 + Level);
      ClearCounts;
      FirstTick := ClockTicks;
      PrepareCampaign(Level);
      GenerateWorld(Level);
      PlaceInitialHero(Level);
      Elapsed := ClockTicks - FirstTick;
      Hash := Digest(Game.Campaign.Flags.Discovery, CampaignBytes);
      RecordResult('world' + Chr(48 + Level), Sample, Elapsed, Hash);
    end;
  FreeMem(Snapshot, CampaignBytes);
  GetMem(Results, SizeOf(TResultArray));
  for A := 25 to 29 do CreatureDefinitions[A] := CreatureDefinitions[A - 25];
  for Sample := 1 to Repeats do
  begin
    ClearCounts;
    Row := 0;
    FirstTick := ClockTicks;
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
            Killed := ResolveStrike(Combat, A, D, AttackerHP, DefenderHP);
          Results^[Row].Killed := Killed;
          Results^[Row].AttackerHP := AttackerHP;
          Results^[Row].DefenderHP := DefenderHP;
          Results^[Row].Halved := Ord(Combat.DemonHalved);
          Results^[Row].Dragon := Combat.DragonResists;
          Results^[Row].Demon := Combat.DemonResists;
          Move(Combat.MutantResists, Results^[Row].Mutants, 5);
          Results^[Row].Seed := RandSeed;
          Inc(Row);
        end;
    Elapsed := ClockTicks - FirstTick;
    Hash := Digest(Results^, SizeOf(TResultArray));
    RecordResult('strikes', Sample, Elapsed, Hash);
  end;
  FreeMem(Results, SizeOf(TResultArray));
  for A := 0 to 5 do
    for D := 0 to 4 do
      case (A + D) mod 3 of
        0: Game.Runtime.BattleField[A, D] := 112 + (A mod 5) * 3;
        1: Game.Runtime.BattleField[A, D] := 32 + (D mod 5) * 3;
        2: Game.Runtime.BattleField[A, D] := 0;
      end;
  for Sample := 1 to Repeats do
  begin
    ClearCounts;
    Hash := 0;
    FirstTick := ClockTicks;
    for RepeatIndex := 1 to 100 do
      for Mode := 0 to 1 do
        for AX := -1 to 6 do
          for AY := -1 to 5 do
          begin
            X := AX;
            Y := AY;
            if Mode = 0 then Found := FindAdjacent(X, Y, 31)
            else Found := FindAdjacent(X, Y, 111);
            Hash := Hash + X + Y + Ord(Found);
          end;
    Elapsed := ClockTicks - FirstTick;
    RecordResult('targets', Sample, Elapsed, Hash);
  end;
  for Sample := 1 to Repeats do
  begin
    ClearCounts;
    Hash := 0;
    Elapsed := 0;
    Counting := false;
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
      if Game.Runtime.BattleResult = 0 then RunEnemyPhase;
      Put(Combat, SizeOf(Combat));
      Put(Game.Runtime.BattleField, SizeOf(Game.Runtime.BattleField));
      Put(Game.Runtime.BattleDistances, SizeOf(Game.Runtime.BattleDistances));
      Put(Game.Runtime.BattleResult, 1);
      Put(Game.Runtime.CurrentBattleSlot, 1);
      Put(RandSeed, SizeOf(RandSeed));
    end;
  end;
    RecordResult('ai_scene', Sample, Elapsed, Hash);
  end;
  for Sample := 1 to Repeats do
  begin
    ClearCounts;
    FirstTick := ClockTicks;
    for RepeatIndex := 1 to 20 do
      for A := 0 to 4 do
        for D := 0 to 4 do
          DrawPictureTile(1761 + A * 12 + D * 4800, 0);
    Elapsed := ClockTicks - FirstTick;
    Hash := VideoDigest;
    RecordResult('tiles', Sample, Elapsed, Hash);
  end;
  StopClock;
  WriteLn(Output, 'heapcheck,0,', InitialHeap - MemAvail, ',0,0,0,0,0,0,0,0,0,0,0');
  Close(Output);
end;
