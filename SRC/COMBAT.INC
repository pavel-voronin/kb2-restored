procedure Battle(EnemyTypes, EnemyCounts: pointer; TerrainDensity: byte);
label
  Finished, NextSurvivor;

var
  Combat: TBattleState;

procedure PaintBattleTerrain;
var
  I, Terrain: byte;

begin
  for I := 0 to 29 do DrawPictureTile(BattleCellOffsets[I], 0);
  for I := 0 to 7 do DrawLine(I + 584, 23, I + 584, 321, 10);

  case Game.Island of
    1, 3: Terrain := 64;
    2: Terrain := 48;
    4, 5: Terrain := 80;
  end;

  I := Random(TerrainDensity);
  while I > 0 do
  begin
    Combat.Cell := Random(149) div 5;
    DrawPictureTile(BattleCellOffsets[Combat.Cell], Terrain);
    Game.BattleField[Combat.Cell mod 6, Combat.Cell div 6] := Terrain;
    Dec(I);
  end;
end;

{$I BATDRAW.INC}

{$I DAMAGE.INC}

{$I PLAYER.INC}

{$I ENEMYAI.INC}
{$I BATMAGIC.INC}

{$I RESERVES.INC}

procedure BattleHelp;

const
  ReserveHelp = '( A )  Ввод pезеpва';
  ShowUnitsHelp = '( B )  Показать своих воинов';
  EndTurnHelp = '( E )  Пеpедача хода пpотивнику';
  FlyHelp = '( F )  Пpиказ: лететь';
  MoveHelp = '( M )  Пpиказ: идти';
  NextUnitHelp = '( N )  Куpсоp на следующего воина';
  ShootHelp = '( S )  Пpиказ: стpелять';
  MagicHelp = '( U )  Волшебство';
  FleeHelp = '(F10)  Бежать с поля боя';

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, ReserveHelp);
  DrawText(false, 2, 248, ShowUnitsHelp);
  DrawText(false, 2, 256, EndTurnHelp);
  DrawText(false, 2, 264, FlyHelp);
  DrawText(false, 2, 272, MoveHelp);
  DrawText(false, 2, 280, NextUnitHelp);
  DrawText(false, 2, 288, ShootHelp);
  DrawText(false, 2, 296, MagicHelp);
  DrawText(false, 2, 304, FleeHelp);
  Game.LastScan := ReadScanCode;
  RedrawLowerRows;
end;

begin
  { Тип 100 означает пустой отряд. }
  FillChar(Game.BattleField, 30, 0);
  FillChar(Game.BattleDistances, 60, 0);
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
  Game.BattleValue := 0;
  Combat.FrozenEnemySlot := 100;
  Combat.EnemyPhaseFinished := true;
  Game.BattleResult := 0;
  Combat.DemonResists := 0;
  Combat.DragonResists := 0;

  for Combat.MainI := 25 to 29 do Combat.MutantResists[Combat.MainI] := 0;
  PaintBattleTerrain;
  for Combat.MainI := 0 to 4 do
    if PEnemySpecies(EnemyTypes)^[Combat.MainI] < 100 then
    begin
      Game.BattleField[5, 4 - Combat.EnemyCount] := Combat.MainI * 3 + 32;
      Game.BattleDistances[5, 4 - Combat.EnemyCount] := PEnemyCounts(EnemyCounts)^[Combat.MainI];
      LoadCreatureArt(PEnemySpecies(EnemyTypes)^[Combat.MainI]);
      CopyRecord(0, Combat.MainI, 8640, Game.PictureBanks[11], Game.PictureBanks[2]);
      MirrorTileArt(Combat.MainI * 3 + 32);
      DrawTile(BattleCellOffsets[(4 - Combat.EnemyCount) * 6 + 5], 0, Combat.MainI * 3 + 32);
      DrawCellCount(5, 4 - Combat.EnemyCount);
      Game.BattlePriceTemporary := CreatureDefinitions[PEnemySpecies(EnemyTypes)^[Combat.MainI]].Cost.Price shr 1;
      Game.BattleValue := PEnemyCounts(EnemyCounts)^[Combat.MainI] * Game.BattlePriceTemporary + Game.BattleValue;
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
    if Game.Army[Combat.MainI].Species < 100 then
    begin
      if Combat.MainI < 5 then
      begin
        Combat.CanMove[Combat.MainI] := true;
        Game.BattleField[0, Combat.PlayerCount] := Combat.MainI * 3 + 112;
        Game.BattleDistances[0, Combat.PlayerCount] := Game.Army[Combat.MainI].Count;
        DrawTile(BattleCellOffsets[Combat.PlayerCount * 6], 0, Game.BattleField[0, Combat.PlayerCount]);
        DrawCellCount(0, Combat.PlayerCount);
        Inc(Combat.PlayerCount);
      end;

      Combat.Player[Combat.MainI].Species := Game.Army[Combat.MainI].Species;
      Combat.Player[Combat.MainI].Count := Game.Army[Combat.MainI].Count;
      Combat.ScaleCount := Game.Army[Combat.MainI].Count;
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
    Game.BattleResult := 2;
    goto Finished
  end;

  Game.BattleTextColumn := Random(30);
  if Game.BattleTextColumn < 15 then Combat.ReadyPlayerCount := Combat.PlayerCount;
  repeat
    if Combat.ReadyPlayerCount >= Combat.PlayerCount then
    begin
      EnemyPhase;

      if Game.BattleResult < 1 then NextPlayerUnit
      else goto Finished;
    end;

    if Combat.RoundMagicReady then
    begin
      CheckLeadership;
      UncontrolledTurn
    end;

    AwaitCellKey(Combat.CursorX, Combat.CursorY, 0, 0);
    if Game.BattleField[Combat.CursorX, Combat.CursorY] > 111 then
      Combat.TargetSlot := (Game.BattleField[Combat.CursorX, Combat.CursorY] - 112) div 3;
    case Game.LastScan of
      68: Game.BattleResult := 2;
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
      30: ReserveMenu;
      48: MarkPlayerUnits;
      18: Combat.ReadyPlayerCount := Combat.PlayerCount;
      33: if (Game.BattleField[Combat.CursorX, Combat.CursorY] > 111) and
        Combat.CanMove[Combat.TargetSlot] and Combat.Player[Combat.TargetSlot].CanFly then
      begin
        HeaderPrompt(17);
        Combat.TeleportSelected := true;
        Combat.TeleportX := Combat.CursorX;
        Combat.TeleportY := Combat.CursorY;
        SelectSpellTarget(7, false);
        NextPlayerUnit;
        Combat.EnemyPhaseFinished := true;
      end;

      50: if (Game.BattleField[Combat.CursorX, Combat.CursorY] > 111) and Combat.CanMove[Combat.TargetSlot] then
      begin
        MovePlayerUnit(Combat.TargetSlot);

        if Game.BattleResult < 1 then NextPlayerUnit;
      end;

      49: NextPlayerUnit;
      31: if (Game.BattleField[Combat.CursorX, Combat.CursorY] > 111) and
        Combat.CanMove[Combat.TargetSlot] and (Combat.Player[Combat.TargetSlot].Shots > 0) then
      begin
        ShootUnit(Combat.Player[Combat.TargetSlot].Shots, Combat.TargetSlot);

        if Game.BattleResult < 1 then NextPlayerUnit;
      end;

      22: if Combat.EnemyPhaseFinished then MagicMenu
      else HeaderPrompt(19);
    end;
  until Game.BattleResult >= 1;
  Game.LastScan := 11;
Finished:
  LoadResourceFile(Game.PictureBanks[2], Game.BattlePictureFileName);

  for Combat.MainI := 0 to 4 do
  begin
    PEnemySpecies(EnemyTypes)^[Combat.MainI] := Combat.Enemy[Combat.MainI].Species;
    PEnemyCounts(EnemyCounts)^[Combat.MainI] := Combat.Enemy[Combat.MainI].Count;
  end;

  for Combat.MainI := 0 to 9 do
    if Game.BattleResult = 2 then Game.Army[Combat.MainI].Species := 100
    else
    begin
      Game.Army[Combat.MainI].Species := Combat.Player[Combat.MainI].Species;

      if Combat.Player[Combat.MainI].Species < 100 then
      begin
        Game.Army[Combat.MainI].Count := Combat.Player[Combat.MainI].Count;
        Combat.LeadershipLimit := (Game.Leadership + Game.LeadershipBonus) div
          CreatureDefinitions[Combat.Player[Combat.MainI].Species].Defense;
        if Combat.Player[Combat.MainI].Count > Combat.LeadershipLimit then
        begin
          Game.Army[Combat.MainI].Species := 100;

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
