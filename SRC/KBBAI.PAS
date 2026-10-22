unit KBBAI;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure EnemyPhase(var Combat: TBattleState);

implementation

uses KBState, KBTables, KBUI, KBGfx, KBInput, Crt, KBBDmg, KBBDraw, KBPlayer;

procedure EnemyPhase(var Combat: TBattleState);
label
  SameFound, AttackRun, NextEnemy;

const
  MovingCaption = ' '#229#174#164#239#226'.';

var
  EnemyAI: TEnemyAIState;

{ При выборе цели в Distance храним оценку атаки. }

procedure RankNeighbour;
var
  Temporary: shortint;

begin
  EnemyAI.StepRanks[0] := EnemyAI.MovementCosts[EnemyAI.CandidateX[0], EnemyAI.CandidateY[0]];
  if EnemyAI.StepRanks[0] < EnemyAI.StepRanks[1] then
  begin
    Temporary := EnemyAI.StepRanks[0];
    EnemyAI.StepRanks[0] := EnemyAI.StepRanks[1];
    EnemyAI.StepRanks[1] := Temporary;
    Temporary := EnemyAI.CandidateX[0];
    EnemyAI.CandidateX[0] := EnemyAI.CandidateX[1];
    EnemyAI.CandidateX[1] := Temporary;
    Temporary := EnemyAI.CandidateY[0];
    EnemyAI.CandidateY[0] := EnemyAI.CandidateY[1];
    EnemyAI.CandidateY[1] := Temporary;
  end;

  if EnemyAI.StepRanks[1] < EnemyAI.StepRanks[2] then
  begin
    Temporary := EnemyAI.StepRanks[1];
    EnemyAI.StepRanks[1] := EnemyAI.StepRanks[2];
    EnemyAI.StepRanks[2] := Temporary;
    Temporary := EnemyAI.CandidateX[1];
    EnemyAI.CandidateX[1] := EnemyAI.CandidateX[2];
    EnemyAI.CandidateX[2] := Temporary;
    Temporary := EnemyAI.CandidateY[1];
    EnemyAI.CandidateY[1] := EnemyAI.CandidateY[2];
    EnemyAI.CandidateY[2] := Temporary;
  end;
end;

function ChooseStep(AbortIfWorse: boolean; X, Y: byte): boolean;
var
  DY, DX: shortint;

procedure CheckAlternative;
begin
  EnemyAI.BestX := X;
  EnemyAI.BestY := Y;

  if FindAdjacent(EnemyAI.BestX, EnemyAI.BestY, 111) then
  begin
    EnemyAI.StepRanks[2] := 0;
    EnemyAI.PreferredTargets[0] := (Game.Runtime.BattleField[EnemyAI.BestX, EnemyAI.BestY] - 112) div 3;
  end
  else
    if EnemyAI.StepRanks[2] > 0 then
    begin
      EnemyAI.BestX := X;
      EnemyAI.BestY := Y;
      EnemyAI.StepsLeft := 1;
    end;
end;

begin
  EnemyAI.StepRanks[0] := 100;
  EnemyAI.StepRanks[1] := 100;
  EnemyAI.StepRanks[2] := 100;

  for DY := -1 to 1 do
    for DX := -1 to 1 do
    begin
      EnemyAI.CandidateX[0] := X + DX;
      EnemyAI.CandidateY[0] := Y + DY;

      if ((DX <> 0) or (DY <> 0)) and
        (EnemyAI.CandidateX[0] >= 0) and (EnemyAI.CandidateX[0] <= 5) and
        (EnemyAI.CandidateY[0] >= 0) and (EnemyAI.CandidateY[0] <= 4) and
        (EnemyAI.StepRanks[0] >= EnemyAI.MovementCosts[EnemyAI.CandidateX[0],
          EnemyAI.CandidateY[0]]) then RankNeighbour;
    end;

  if AbortIfWorse and (EnemyAI.StepRanks[2] > EnemyAI.PreviousRank) then CheckAlternative
  else
    if EnemyAI.StepRanks[2] < EnemyAI.StepRanks[1] then
    begin
      EnemyAI.BestX := EnemyAI.CandidateX[2];
      EnemyAI.BestY := EnemyAI.CandidateY[2];
    end
    else
      if (X <> EnemyAI.CandidateX[2]) and (Y <> EnemyAI.CandidateY[2]) then
      begin
        EnemyAI.BestX := EnemyAI.CandidateX[2];
        EnemyAI.BestY := EnemyAI.CandidateY[2];
      end
      else
        if (X <> EnemyAI.CandidateX[1]) and (Y <> EnemyAI.CandidateY[1]) then
        begin
          EnemyAI.BestX := EnemyAI.CandidateX[1];
          EnemyAI.BestY := EnemyAI.CandidateY[1];
        end
        else
          if EnemyAI.StepRanks[1] = EnemyAI.StepRanks[0] then
            if (X <> EnemyAI.CandidateX[0]) and (Y <> EnemyAI.CandidateY[0]) then
            begin
              EnemyAI.BestX := EnemyAI.CandidateX[0];
              EnemyAI.BestY := EnemyAI.CandidateY[0];
            end
            else
            begin
              EnemyAI.BestX := EnemyAI.CandidateX[1];
              EnemyAI.BestY := EnemyAI.CandidateY[1];
            end
          else
          begin
            EnemyAI.BestX := EnemyAI.CandidateX[2];
            EnemyAI.BestY := EnemyAI.CandidateY[2];
          end;

  ChooseStep := EnemyAI.StepRanks[2] = 0;
  EnemyAI.PreviousRank := EnemyAI.StepRanks[2];
end;

procedure BuildCostMap(Slot: byte);
var
  Y, X: shortint;

begin
  FindUnitCell(Slot, 112, EnemyAI.TargetX, EnemyAI.TargetY);
  FindUnitCell(EnemyAI.EnemySlot, 32, EnemyAI.EnemyX, EnemyAI.EnemyY);

  for Y := 0 to 4 do
    for X := 0 to 5 do
    begin
      EnemyAI.Distance := Abs(EnemyAI.TargetX - X) + Abs(EnemyAI.TargetY - Y);

      if EnemyAI.Distance = 0 then EnemyAI.MovementCosts[X, Y] := Lo(EnemyAI.Distance)
      else if Game.Runtime.BattleField[X, Y] = 0 then EnemyAI.MovementCosts[X, Y] := Lo(EnemyAI.Distance)
      else EnemyAI.MovementCosts[X, Y] := 255;
    end;
end;

procedure FlyToTarget;
label
  Found;

var
  DY, DX, Radius: shortint;

begin
  Radius := 1;
  repeat
    for DY := -Radius to Radius do
      for DX := -Radius to Radius do
      begin
        EnemyAI.BestX := EnemyAI.TargetX + DX;
        EnemyAI.BestY := EnemyAI.TargetY + DY;

        if (EnemyAI.BestX >= 0) and (EnemyAI.BestX <= 5) and
          (EnemyAI.BestY >= 0) and (EnemyAI.BestY <= 4) and
          (Game.Runtime.BattleField[EnemyAI.BestX, EnemyAI.BestY] = 0) then goto Found;
      end;

    Inc(Radius);
  until false;
Found:
  RelocateUnit(EnemyAI.EnemyX, EnemyAI.EnemyY, EnemyAI.BestX, EnemyAI.BestY);
end;

procedure FrozenEnemy(Slot: byte);
var
  UnknownLocal: byte;

begin
  HeaderPrompt(28);
  FindUnitCell(Slot, 32, EnemyAI.EnemyX, EnemyAI.EnemyY);
  HighlightCell(EnemyAI.EnemyX, EnemyAI.EnemyY);
  Combat.FrozenEnemySlot := 100;
end;

procedure PoisonedEnemy(Slot, DamageFactor: byte);
var
  UnknownLocal: byte;

begin
  HeaderPrompt(22);
  FindUnitCell(Slot, 32, EnemyAI.EnemyX, EnemyAI.EnemyY);
  HighlightCell(EnemyAI.EnemyX, EnemyAI.EnemyY);
  Game.Runtime.BattleTextColumn := ApplyDamage(Combat.Enemy[Slot].Species, Game.Campaign.MagicPower *
    DamageFactor,
    Combat.Enemy[Slot].HitPoints);

  if Game.Runtime.BattleTextColumn > 0 then ReportEnemyLoss(Combat, Slot, EnemyAI.EnemyX, EnemyAI.EnemyY);
end;

procedure ChooseFlight;
label
  Found;

var
  I: byte;

begin
  for I := 0 to 2 do if EnemyAI.PreferredTargets[I] < 5 then goto Found;
Found:
  BuildCostMap(EnemyAI.PreferredTargets[I]);
  EnemyAI.PreviousRank := Abs(EnemyAI.TargetX - EnemyAI.EnemyX) + Abs(EnemyAI.TargetY - EnemyAI.EnemyY);

  if not ChooseStep(true, EnemyAI.EnemyX, EnemyAI.EnemyY) then FlyToTarget;
end;

function ShooterTurn: byte;
label
  TargetFound, Retry, Escape, NoEscape, SeekEscape;

var
  DX, DY, TX, TY, Radius, NearX, NearY: shortint;

begin
  EnemyAI.StepsLeft := CreatureDefinitions[Combat.Enemy[EnemyAI.EnemySlot].Species].Movement;
  for DX := 0 to 2 do if EnemyAI.PreferredTargets[DX] < 5 then goto TargetFound;
TargetFound:
  BuildCostMap(EnemyAI.PreferredTargets[DX]);

  if Combat.Enemy[EnemyAI.EnemySlot].Shots = 0 then ShooterTurn := 3
  else
  begin
Retry:
    NearX := EnemyAI.EnemyX;
    NearY := EnemyAI.EnemyY;

    if FindAdjacent(NearX, NearY, 111) then goto SeekEscape;
      HighlightCell(EnemyAI.EnemyX, EnemyAI.EnemyY);
      AttackUnit(Combat, EnemyAI.EnemyX, EnemyAI.EnemyY, EnemyAI.TargetX, EnemyAI.TargetY);
      Dec(Combat.Enemy[EnemyAI.EnemySlot].Shots);
      ShooterTurn := Game.Runtime.BattleResult;
      Exit;
SeekEscape:
      Radius := EnemyAI.StepsLeft - 1;

      for DX := -Radius to Radius do
        for DY := -Radius to Radius do
        begin
          TX := EnemyAI.EnemyX + DX;
          TY := EnemyAI.EnemyY + DY;

          if (TX >= 0) and (TX <= 5) and (TY >= 0) and (TY <= 4) then
            if FindAdjacent(TX, TY, 111) then
            begin
            end
            else if Game.Runtime.BattleField[TX, TY] = 0 then goto Escape;
        end;

NoEscape:
      BuildCostMap((Game.Runtime.BattleField[NearX, NearY] - 112) div 3);
      ShooterTurn := 3;
      Exit;
Escape:
      NearX := EnemyAI.EnemyX;
      NearY := EnemyAI.EnemyY;

      repeat
        if DX < 0 then
        begin
          Dec(NearX);
          Inc(DX)
        end
        else if DX > 0 then
        begin
          Inc(NearX);
          Dec(DX)
        end;

        if DY < 0 then
        begin
          Dec(NearY);
          Inc(DY)
        end
        else if DY > 0 then
        begin
          Inc(NearY);
          Dec(DY)
        end;

        if Game.Runtime.BattleField[NearX, NearY] = 0 then
        begin
          HighlightCell(EnemyAI.EnemyX, EnemyAI.EnemyY);
          RelocateUnit(EnemyAI.EnemyX, EnemyAI.EnemyY, NearX, NearY);
        end
        else
        begin
          NearX := EnemyAI.EnemyX;
          NearY := EnemyAI.EnemyY;

          if FindAdjacent(NearX, NearY, 111) then goto NoEscape;
        end;
      until (DX = 0) and (DY = 0);
      goto Retry;
  end;
end;

begin
  while KeyPressed do Game.Runtime.LastScan := ReadScanCode;
  FillChar(Combat.CanMove, 5, 1);

  for EnemyAI.ScanIndex := 0 to 4 do
    if Combat.Player[EnemyAI.ScanIndex].Species < 100 then
    begin
      Combat.Retaliations[EnemyAI.ScanIndex] := CreatureDefinitions[Combat.Player[EnemyAI.ScanIndex].Species].Flags
        shr 5;
      Combat.Retaliations[EnemyAI.ScanIndex] := Combat.Retaliations[EnemyAI.ScanIndex] and 3;
    end;

  for EnemyAI.EnemySlot := 0 to 4 do
  begin
    if Combat.Enemy[EnemyAI.EnemySlot].Species >= 100 then goto NextEnemy;
    FillChar(EnemyAI.PreferredTargets, 3, 100);
    ClearRectangle(16, 8, 584, 15);
    Game.Runtime.TextBuffer := CreatureDefinitions[Combat.Enemy[EnemyAI.EnemySlot].Species].Name + MovingCaption;
    DrawText(false, 2, 8, Game.Runtime.TextBuffer);

    if Combat.FrozenEnemySlot = EnemyAI.EnemySlot then
    begin
      FrozenEnemy(EnemyAI.EnemySlot);
      goto NextEnemy;
    end;

    if Combat.Poison[EnemyAI.EnemySlot] > 0 then
    begin
      case Combat.Poison[EnemyAI.EnemySlot] of
        1: Inc(Combat.Poison[EnemyAI.EnemySlot]);
        2: begin
          PoisonedEnemy(EnemyAI.EnemySlot, 30);
          Inc(Combat.Poison[EnemyAI.EnemySlot])
        end;

        3: begin
          PoisonedEnemy(EnemyAI.EnemySlot, 50);
          Combat.Poison[EnemyAI.EnemySlot] := 0
        end;
      end;

      if Game.Runtime.BattleResult = 1 then Exit
      else if Combat.Poison[EnemyAI.EnemySlot] = 0 then goto NextEnemy;
    end;

    for EnemyAI.PreferredTargets[0] := 0 to 4 do
      if Combat.Player[EnemyAI.PreferredTargets[0]].Species = Combat.Enemy[EnemyAI.EnemySlot].Species then goto
        SameFound;
    EnemyAI.PreferredTargets[0] := 100;
SameFound:
    for EnemyAI.ScanIndex := 0 to 4 do
      if (Combat.Player[EnemyAI.ScanIndex].Species < 100) and (Combat.Player[EnemyAI.ScanIndex].Shots > 0) then
        if EnemyAI.PreferredTargets[1] < 5 then
        begin
          if Combat.Player[EnemyAI.PreferredTargets[1]].AttackPower < Combat.Player[EnemyAI.ScanIndex].AttackPower
    then
            EnemyAI.PreferredTargets[1] := EnemyAI.ScanIndex;
        end
        else EnemyAI.PreferredTargets[1] := EnemyAI.ScanIndex;
    if (EnemyAI.PreferredTargets[0] < 5) and (EnemyAI.PreferredTargets[1] < 5) then
      if Combat.Player[EnemyAI.PreferredTargets[0]].AttackPower < Combat.Player[EnemyAI.PreferredTargets[1]].
        AttackPower then
      begin
        EnemyAI.ScanIndex := EnemyAI.PreferredTargets[0];
        EnemyAI.PreferredTargets[0] := EnemyAI.PreferredTargets[1];
        EnemyAI.PreferredTargets[1] := EnemyAI.ScanIndex;
      end;

    EnemyAI.Distance := 0;
    for EnemyAI.ScanIndex := 0 to 4 do
      if Combat.Player[EnemyAI.ScanIndex].Species < 100 then
        if Combat.Player[EnemyAI.ScanIndex].AttackPower > EnemyAI.Distance then
        begin
          EnemyAI.Distance := Combat.Player[EnemyAI.ScanIndex].AttackPower;
          EnemyAI.PreferredTargets[2] := EnemyAI.ScanIndex;
        end;

    if Combat.Enemy[EnemyAI.EnemySlot].CanFly then ChooseFlight
    else if Combat.Enemy[EnemyAI.EnemySlot].Shots > 0 then
    begin
      EnemyAI.TurnResult := ShooterTurn;

      if EnemyAI.TurnResult = 2 then Exit;
      if EnemyAI.TurnResult = 3 then goto AttackRun;
      goto NextEnemy;
    end;

    for EnemyAI.ScanIndex := 0 to 2 do
      if EnemyAI.PreferredTargets[EnemyAI.ScanIndex] < 5 then
      begin
        BuildCostMap(EnemyAI.PreferredTargets[EnemyAI.ScanIndex]);
        EnemyAI.StepsLeft := CreatureDefinitions[Combat.Enemy[EnemyAI.EnemySlot].Species].Movement;
        EnemyAI.TestX := EnemyAI.EnemyX;
        EnemyAI.TestY := EnemyAI.EnemyY;

        repeat
          if ChooseStep(false, EnemyAI.TestX, EnemyAI.TestY) then goto AttackRun
          else Dec(EnemyAI.StepsLeft);
          EnemyAI.TestX := EnemyAI.BestX;
          EnemyAI.TestY := EnemyAI.BestY;
        until EnemyAI.StepsLeft = 0;
      end;

    if CreatureDefinitions[Combat.Enemy[EnemyAI.EnemySlot].Species].Movement = 1 then
    begin
      EnemyAI.BestX := EnemyAI.EnemyX;
      EnemyAI.BestY := EnemyAI.EnemyY;

      if FindAdjacent(EnemyAI.BestX, EnemyAI.BestY, 111) then
      begin
        EnemyAI.TurnResult := (Game.Runtime.BattleField[EnemyAI.BestX, EnemyAI.BestY] - 112) div 3;
        BuildCostMap(EnemyAI.TurnResult);
        goto AttackRun;
      end;
    end;

    for EnemyAI.ScanIndex := 0 to 2 do
      if EnemyAI.PreferredTargets[EnemyAI.ScanIndex] < 5 then
      begin
        BuildCostMap(EnemyAI.PreferredTargets[EnemyAI.ScanIndex]);
        goto AttackRun;
      end;

AttackRun:
    EnemyAI.StepsLeft := CreatureDefinitions[Combat.Enemy[EnemyAI.EnemySlot].Species].Movement;
    repeat
      HighlightCell(EnemyAI.EnemyX, EnemyAI.EnemyY);
      EnemyAI.PreviousRank := Abs(EnemyAI.TargetX - EnemyAI.EnemyX) + Abs(EnemyAI.TargetY - EnemyAI.EnemyY);

      if ChooseStep(true, EnemyAI.EnemyX, EnemyAI.EnemyY) then
      begin
        AttackUnit(Combat, EnemyAI.EnemyX, EnemyAI.EnemyY, EnemyAI.BestX, EnemyAI.BestY);

        if Game.Runtime.BattleResult = 2 then Exit;
        if Game.Runtime.BattleDistances[EnemyAI.BestX, EnemyAI.BestY] > 0 then
        begin
          Combat.TargetSlot := (Game.Runtime.BattleField[EnemyAI.BestX, EnemyAI.BestY] - 112) div 3;

          if Combat.Retaliations[Combat.TargetSlot] > 0 then
          begin
            AttackUnit(Combat, EnemyAI.BestX, EnemyAI.BestY, EnemyAI.EnemyX, EnemyAI.EnemyY);
            Dec(Combat.Retaliations[Combat.TargetSlot]);
          end;
        end;

        EnemyAI.StepsLeft := 1;
      end
      else RelocateUnit(EnemyAI.EnemyX, EnemyAI.EnemyY, EnemyAI.BestX, EnemyAI.BestY);
      Dec(EnemyAI.StepsLeft);
    until EnemyAI.StepsLeft = 0;
NextEnemy:
  end;

  FillChar(Combat.CanMove, 5, 1);
  for EnemyAI.ScanIndex := 0 to 4 do
    if Combat.Enemy[EnemyAI.ScanIndex].Species < 100 then
    begin
      Combat.Retaliations[EnemyAI.ScanIndex] := CreatureDefinitions[Combat.Enemy[EnemyAI.ScanIndex].Species].Flags
        shr 5;
      Combat.Retaliations[EnemyAI.ScanIndex] := Combat.Retaliations[EnemyAI.ScanIndex] and 3;
    end;

  Combat.ReadyPlayerCount := 0;
  Combat.EnemyPhaseFinished := true;
  Combat.RoundMagicReady := true;
end;

end.
