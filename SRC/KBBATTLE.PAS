unit KBBattle;
{$G+,R-,S-,I+,A+}

interface

procedure Battle(EnemyTypes, EnemyCounts: pointer; TerrainDensity: byte);

implementation

uses KBState, KBBType, KBUI, KBArt, KBGfx, KBFiles, KBTables, Crt, KBBDraw, KBPlayer, KBBAI, KBBMagic, KBBRes,
    KBBScene;

procedure Battle(EnemyTypes, EnemyCounts: pointer; TerrainDensity: byte);
label
  Finished, NextSurvivor;

var
  Combat: TBattleState;

begin
  { Тип 100 означает пустой отряд. }
  FillChar(Game.Runtime.BattleField, 30, 0);
  FillChar(Game.Runtime.BattleDistances, 60, 0);
  FillChar(Combat.CanMove, 5, 0);
  FillChar(Combat.Poison, 5, 0);
  FillChar(Combat.Enemy, 10, 100);
  FillChar(Combat.Player, 10, 100);
  Combat.EnemyCount := 0;
  Combat.CursorX := 0;
  Combat.CursorY := 0;
  Combat.MaxReserve := 9;
  Combat.DemonHalved := false;
  Combat.RoundMagicReady := true;
  Game.Runtime.BattleValue := 0;
  Combat.FrozenEnemySlot := 100;
  Combat.EnemyPhaseFinished := true;
  Game.Runtime.BattleResult := 0;
  Combat.DemonResists := 0;
  Combat.DragonResists := 0;

  for Combat.MainI := 25 to 29 do Combat.MutantResists[Combat.MainI] := 0;
  PaintBattleTerrain(Combat, TerrainDensity);
  for Combat.MainI := 0 to 4 do
    if PEnemySpecies(EnemyTypes)^[Combat.MainI] < 100 then
    begin
      Game.Runtime.BattleField[5, 4 - Combat.EnemyCount] := Combat.MainI * 3 + 32;
      Game.Runtime.BattleDistances[5, 4 - Combat.EnemyCount] := PEnemyCounts(EnemyCounts)^[Combat.MainI];
      LoadCreatureArt(PEnemySpecies(EnemyTypes)^[Combat.MainI]);
      CopyRecord(0, Combat.MainI, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[2]);
      MirrorTileArt(Combat.MainI * 3 + 32);
      DrawTile(BattleCellOffsets[(4 - Combat.EnemyCount) * 6 + 5], 0, Combat.MainI * 3 + 32);
      DrawCellCount(5, 4 - Combat.EnemyCount);
      Game.Runtime.BattlePriceTemporary := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].Cost.Price
    shr 1;
      Game.Runtime.BattleValue := PEnemyCounts(EnemyCounts)^[Combat.MainI] * Game.Runtime.BattlePriceTemporary +
    Game.Runtime.BattleValue;
      Combat.Enemy[Combat.MainI].Species := PEnemySpecies(EnemyTypes)^[Combat.MainI];
      Combat.Enemy[Combat.MainI].Count := PEnemyCounts(EnemyCounts)^[Combat.MainI];
      Combat.Enemy[Combat.MainI].InitialCount := Combat.Enemy[Combat.MainI].Count;
      Combat.ScaleCount := PEnemyCounts(EnemyCounts)^[Combat.MainI];
      Combat.Enemy[Combat.MainI].HitPoints := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].
        Defense * Combat.ScaleCount;
      Combat.Enemy[Combat.MainI].AttackPower := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].
        Attack * Combat.ScaleCount;
      Combat.Enemy[Combat.MainI].Shots := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].Flags and 31;
      Combat.Enemy[Combat.MainI].CanFly := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].Flags >= 128;
      Combat.Retaliations[Combat.MainI] := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].Flags shr 5;
      Combat.Retaliations[Combat.MainI] := Combat.Retaliations[Combat.MainI] and 3;
      Inc(Combat.EnemyCount);
    end
    else Combat.Enemy[Combat.MainI].Species := 100;
  { Первые пять отрядов выходят на поле, остальные остаются в резерве. }
  Combat.PlayerCount := 0;
  Combat.ReadyPlayerCount := 0;

  for Combat.MainI := 0 to 9 do
    if Game.Campaign.Army[Combat.MainI].Species < 100 then
    begin
      if Combat.MainI < 5 then
      begin
        Combat.CanMove[Combat.MainI] := true;
        Game.Runtime.BattleField[0, Combat.PlayerCount] := Combat.MainI * 3 + 112;
        Game.Runtime.BattleDistances[0, Combat.PlayerCount] := Game.Campaign.Army[Combat.MainI].Count;
        DrawTile(BattleCellOffsets[Combat.PlayerCount * 6], 0, Game.Runtime.BattleField[0, Combat.PlayerCount]);
        DrawCellCount(0, Combat.PlayerCount);
        Inc(Combat.PlayerCount);
      end;

      Combat.Player[Combat.MainI].Species := Game.Campaign.Army[Combat.MainI].Species;
      Combat.Player[Combat.MainI].Count := Game.Campaign.Army[Combat.MainI].Count;
      Combat.ScaleCount := Game.Campaign.Army[Combat.MainI].Count;
      Combat.Player[Combat.MainI].HitPoints := CreatureDefinitions[Combat.Player[Combat.MainI].Species].Defense *
        Combat.ScaleCount;
      Combat.Player[Combat.MainI].AttackPower := CreatureDefinitions[Combat.Player[Combat.MainI].Species].Attack *
        Combat.ScaleCount;
      Combat.Player[Combat.MainI].Shots := CreatureDefinitions[Combat.Player[Combat.MainI].Species].Flags and 31;
      Combat.Player[Combat.MainI].InitialCount := Combat.Player[Combat.MainI].Count;
      Combat.Player[Combat.MainI].CanFly := CreatureDefinitions[Combat.Player[Combat.MainI].Species].Flags >= 128;
    end
    else Combat.Player[Combat.MainI].Species := 100;
  if Combat.PlayerCount = 0 then
  begin
    Game.Runtime.BattleResult := 2;
    goto Finished
  end;

  Game.Runtime.BattleTextColumn := Random(30);
  if Game.Runtime.BattleTextColumn < 15 then Combat.ReadyPlayerCount := Combat.PlayerCount;
  repeat
    if Combat.ReadyPlayerCount >= Combat.PlayerCount then
    begin
      EnemyPhase(Combat);

      if Game.Runtime.BattleResult < 1 then NextPlayerUnit(Combat)
      else goto Finished;
    end;

    if Combat.RoundMagicReady then
    begin
      CheckLeadership(Combat);
      UncontrolledTurn(Combat)
    end;

    AwaitCellKey(Combat, Combat.CursorX, Combat.CursorY, 0, 0);
    if Game.Runtime.BattleField[Combat.CursorX, Combat.CursorY] > 111 then
      Combat.TargetSlot := (Game.Runtime.BattleField[Combat.CursorX, Combat.CursorY] - 112) div 3;
    case Game.Runtime.LastScan of
      68: Game.Runtime.BattleResult := 2;
      71: if (Combat.CursorX > 0) and (Combat.CursorY > 0) then
      begin
        Dec(Combat.CursorX);
        Dec(Combat.CursorY)
      end;

      72: if Combat.CursorY > 0 then Dec(Combat.CursorY);
      73: if (Combat.CursorX < 5) and (Combat.CursorY > 0) then
      begin
        Inc(Combat.CursorX);
        Dec(Combat.CursorY)
      end;

      75: if Combat.CursorX > 0 then Dec(Combat.CursorX);
      77: if Combat.CursorX < 5 then Inc(Combat.CursorX);
      79: if (Combat.CursorX > 0) and (Combat.CursorY < 4) then
      begin
        Dec(Combat.CursorX);
        Inc(Combat.CursorY)
      end;

      80: if Combat.CursorY < 4 then Inc(Combat.CursorY);
      81: if (Combat.CursorX < 5) and (Combat.CursorY < 4) then
      begin
        Inc(Combat.CursorX);
        Inc(Combat.CursorY)
      end;

      24: BattleHelp;
      30: ReserveMenu(Combat);
      48: MarkPlayerUnits(Combat);
      18: Combat.ReadyPlayerCount := Combat.PlayerCount;
      33: if (Game.Runtime.BattleField[Combat.CursorX, Combat.CursorY] > 111) and
        Combat.CanMove[Combat.TargetSlot] and Combat.Player[Combat.TargetSlot].CanFly then
      begin
        HeaderPrompt(17);
        Combat.TeleportSelected := true;
        Combat.TeleportX := Combat.CursorX;
        Combat.TeleportY := Combat.CursorY;
        SelectSpellTarget(Combat, 7, false);
        NextPlayerUnit(Combat);
        Combat.EnemyPhaseFinished := true;
      end;

      50: if (Game.Runtime.BattleField[Combat.CursorX, Combat.CursorY] > 111) and Combat.CanMove[Combat.TargetSlot]
    then
      begin
        MovePlayerUnit(Combat, Combat.TargetSlot);

        if Game.Runtime.BattleResult < 1 then NextPlayerUnit(Combat);
      end;

      49: NextPlayerUnit(Combat);
      31: if (Game.Runtime.BattleField[Combat.CursorX, Combat.CursorY] > 111) and
        Combat.CanMove[Combat.TargetSlot] and (Combat.Player[Combat.TargetSlot].Shots > 0) then
      begin
        ShootUnit(Combat, Combat.Player[Combat.TargetSlot].Shots, Combat.TargetSlot);

        if Game.Runtime.BattleResult < 1 then NextPlayerUnit(Combat);
      end;

      22: if Combat.EnemyPhaseFinished then MagicMenu(Combat)
      else HeaderPrompt(19);
    end;
  until Game.Runtime.BattleResult >= 1;
  Game.Runtime.LastScan := 11;
Finished:
  LoadResourceFile(Game.Runtime.PictureBanks[2], Game.Runtime.BattlePictureFileName);

  for Combat.MainI := 0 to 4 do
  begin
    PEnemySpecies(EnemyTypes)^[Combat.MainI] := Combat.Enemy[Combat.MainI].Species;
    PEnemyCounts(EnemyCounts)^[Combat.MainI] := Combat.Enemy[Combat.MainI].Count;
  end;

  for Combat.MainI := 0 to 9 do
    if Game.Runtime.BattleResult = 2 then Game.Campaign.Army[Combat.MainI].Species := 100
    else
    begin
      Game.Campaign.Army[Combat.MainI].Species := Combat.Player[Combat.MainI].Species;

      if Combat.Player[Combat.MainI].Species < 100 then
      begin
        Game.Campaign.Army[Combat.MainI].Count := Combat.Player[Combat.MainI].Count;
        Combat.LeadershipLimit := (Game.Campaign.Leadership + Game.Campaign.LeadershipBonus) div
          CreatureDefinitions[Combat.Player[Combat.MainI].Species].Defense;
        if Combat.Player[Combat.MainI].Count > Combat.LeadershipLimit then
        begin
          Game.Campaign.Army[Combat.MainI].Species := 100;

          if Combat.MainI < 5 then
            for Combat.SpawnI := 0 to 4 do
              if PEnemySpecies(EnemyTypes)^[Combat.SpawnI] = 100 then
              begin
                PEnemySpecies(EnemyTypes)^[Combat.SpawnI] := Combat.Player[Combat.MainI].Species;
                PEnemyCounts(EnemyCounts)^[Combat.SpawnI] := Combat.Player[Combat.MainI].Count;
                goto NextSurvivor;
              end;
        end;
      end;

NextSurvivor:
    end;
end;

end.
