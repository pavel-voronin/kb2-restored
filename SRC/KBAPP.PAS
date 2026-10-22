unit KBApp;
{$G+,R-,S-,I+,A+}

interface

procedure RunGame;

implementation

uses KBRandom, Dos, Crt, KBTypes, KBTables, KBState, KBWorld, KBGfx, KBInput, KBFiles, KBArt, KBUI,
  KBView, KBSave, KBStart, KBWorker, KBCal, KBSound, KBBattle, KBLpt, KBAdvent, KBCampgn,
  KBEvents;

procedure FirstSeriesEnding;
begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 23, 272, 'КОНЕЦ ПЕРВОЙ СЕРИИ');
  Game.LastScan := ReadScanCode;
  CleanupGame;
  Halt;
end;

procedure TreasureVisit;
begin
  EncounterLanding;
  Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 0;
  Game.GenerationCount := Random(IslandFactors[Game.Island]);
  DrawDialog(8, 230, 488, 320);

  if Game.GenerationCount < 8 then
  begin
    if Game.GenerationCount < 3 then
    begin
      DrawText(false, 5, 272, 'Mаксимальное количество волшебств увеличивается на 1');
      Inc(Game.ScrollCapacity);
      Game.LastScan := Ord(ReadKey);
    end
    else
    begin
      Game.ActionScratch := Random(139) div 10;
      DrawText(false, 19, 272, 'Волшебство');
      DrawText(false, 30, 272, ScrollNames[shortint(Game.ActionScratch)]);
      Inc(Game.Scrolls[shortint(Game.ActionScratch)]);
      Game.LastScan := Ord(ReadKey);
    end;
  end
  else if Game.GenerationCount < 15 then
  begin
    Inc(Game.Income, IslandFactors[Game.Island] * 10);
    DrawText(false, 7, 248, 'Вы нашли алмазы и Великодушный Коpоль увеличивает');
    DrawText(false, 17, 264, 'Ваше жалование на ($):');
    Str(IslandFactors[Game.Island] * 10, Game.TextBuffer);
    DrawText(false, 38, 264, Game.TextBuffer);
    PlayCue(2);
    Game.LastScan := ReadScanCode;
  end
  else
  begin
    Game.GenerationCount := (Game.GenerationCount + TreasureGoldBases[Game.Island]) * 10;
    Game.GenerationLimit := Game.GenerationCount div 50;
    Str(Game.GenerationCount, Game.TextBuffer);
    DrawText(false, 2, 240, 'ЗОЛОТО: $');
    DrawText(false, 11, 240, Game.TextBuffer);
    DrawText(false, 2, 256, '1) Увеличить золотой запас');
    DrawText(false, 2, 264, '2) Раздать воинам, повысив свой автоpитет на:');
    Str(Game.GenerationLimit, Game.TextBuffer);
    DrawText(false, 48, 264, Game.TextBuffer);
    Game.CueFrequency := Game.GenerationCount;
    PlayCue(1);

    repeat
      Game.LastScan := Ord(ReadKey);
      case Game.LastScan of
        49: begin
          Game.Gold := Game.Gold + Game.GenerationCount;
          RefreshGold
        end;

        50: Game.Leadership := Game.Leadership + Game.GenerationLimit;
      end;
    until (Game.LastScan = 49) or (Game.LastScan = 50);
  end;
end;

procedure UndergroundVisit;
begin
  EncounterLanding;
  PlayCue(3);

  if Game.Underground[Game.Island, 1].X = Game.GenerationX then
    if Game.Underground[Game.Island, 1].Y = Game.GenerationY then
    begin
      Game.GenerationX := Game.Underground[Game.Island, 2].X + 1;
      Game.GenerationY := Game.Underground[Game.Island, 2].Y;
    end
    else
    begin
      Game.GenerationX := Game.Underground[Game.Island, 1].X + 1;
      Game.GenerationY := Game.Underground[Game.Island, 1].Y;
    end
  else
  begin
    Game.GenerationX := Game.Underground[Game.Island, 1].X + 1;
    Game.GenerationY := Game.Underground[Game.Island, 1].Y;
  end;
end;

function FindWanderingArmy(X, Y: byte): shortint;
var
  I: shortint;

begin
  I := -1;
  repeat
    Inc(I)
  until (Game.WanderingArmies[Game.Island, I].X = X) and (Game.WanderingArmies[Game.Island, I].Y = Y);
  FindWanderingArmy := I;
end;

procedure WanderingArmyVisit;
label
  Finished, UnknownArmy, AskAgain, OfferBattle;

var
  I: shortint;
  Total, Reserve: word;

begin
  Total := 0;
  Reserve := 0;

  for I := 0 to 9 do
    if Game.Army[I].Species < 100 then
    begin
      if I > 4 then Inc(Reserve);
      Inc(Total);
    end;

  I := FindWanderingArmy(Game.GenerationX, Game.GenerationY);
  if ArmyReport(TReportSpecies(Game.WanderingArmies[Game.Island, I].Species),
    TReportCounts(Game.WanderingArmies[Game.Island, I].Counts), ' ') then goto Finished;
  case Reserve of
    1: if Game.MagicPower < 2 then goto UnknownArmy;
    2: if Game.MagicPower < 5 then goto UnknownArmy;
    3: if Game.MagicPower < 10 then goto UnknownArmy;
    4: if Game.MagicPower < 20 then goto UnknownArmy;
    5: if Game.MagicPower < 35 then goto UnknownArmy;
  end;

  goto OfferBattle;
UnknownArmy:
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 20, 272, 'Войско неизвестно!');
OfferBattle:
  if (Game.EnemyGrace = 0) or (Total > 0) then
  begin
    DrawText(false, 14, 304, 'Дpаться будешь ( Y-да / N-нет ) ?');
AskAgain:
    Game.LastScan := ReadScanCode;

    if Game.LastScan = 21 then
    begin
      if Game.ArmyAvailable then
      begin
        Battle(@Game.WanderingArmies[Game.Island, I].Species, @Game.WanderingArmies[Game.Island, I].Counts, 10);

        if Game.BattleResult = 2 then DefeatReport
        else VictoryReport(I, 5);
        RestoreControls;
      end
      else GameOver;
    end
    else if Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y] = 5 then goto AskAgain;
  end
  else ShowNotice(9);
Finished:
end;

procedure BoardShip;
var
  OldHeading: boolean;

begin
  Game.Hero.X := Game.GenerationX;
  Game.Hero.Y := Game.GenerationY;
  Game.ShipAbandonBlocked := true;
  AbandonShip;
  Game.ShipOwned := true;
  OldHeading := Game.Heading;
  Game.Heading := boolean(Game.ShipHeading);
  Game.ShipHeading := Ord(OldHeading);
end;



procedure DismissArmy;
label
  Finished;

var
  Rows: array[0..9] of byte;
  I, Row, Count: byte;
  Text: string[60];

begin
  Row := 0;
  Count := 0;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(2);
  DrawText(false, 17, 240, '- УВОЛЬНЕНИЕ В ЗАПАС -');

  for I := 0 to 9 do
    if Game.Army[I].Species < 100 then
    begin
      Inc(Count);
      Rows[Row] := I;
      Str(Row, Game.TextBuffer);
      Text := Game.TextBuffer + ') ' + CreatureDefinitions[Game.Army[I].Species].Name;
      Game.GenerationCount := Row mod 5 * 8 + 256;
      Game.GenerationLimit := Row div 5 * 20 + 3;
      DrawText(false, Lo(Game.GenerationLimit), Game.GenerationCount, Text);
      Inc(Row);
    end;

  if Count > 0 then
  begin
    repeat
      Game.LastScan := Ord(ReadKey)
    until (Game.LastScan in [48..57]) or (Game.LastScan = 27);

    if Game.LastScan = 27 then
    begin
      HeaderPrompt(0);
      goto Finished
    end;

    Val(Chr(Game.LastScan), Row, Game.GenerationCount);
    if Game.Army[Rows[Row]].Species < 100 then
    begin
      Game.Army[Rows[Row]].Species := 100;

      if Count = 1 then Game.ArmyAvailable := false;
    end;
  end
  else
  begin
    DrawText(false, 17, 264, 'А увольнять некого.');
    Game.LastScan := ReadScanCode;
  end;

  HeaderPrompt(0);
Finished:
end;

procedure SearchRitualSpell;
label
  LandingFound;

var
  I, J: shortint;
  Species: byte;
  UnknownLocal: array[1..5] of byte;

begin
  if (Game.Island = Game.HiddenSpellIsland) and (Game.GenerationX = Game.HiddenSpellPosition.X)
    and (Game.GenerationY = Game.HiddenSpellPosition.Y) then
  begin
    Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 23;

    for I := -1 to 1 do
      for J := -1 to 1 do
        if Game.Map[Game.Island, Game.GenerationX + I, Game.GenerationY + J] = 0 then goto LandingFound;
LandingFound:
    Game.Hero.X := Game.GenerationX + I;
    Game.Hero.Y := Game.GenerationY + J;
    RandomizeGame;

    for I := 0 to 4 do
    begin
      Species := Random(249) div 10;
      Game.GuardianCounts[I] := Game.Leadership div CreatureDefinitions[Species].Defense;

      if Game.GuardianCounts[I] > 0 then Game.GuardianSpecies[I] := Species
      else Game.GuardianSpecies[I] := 100;
    end;
  end
  else ShowNotice(21);
end;

procedure HeroStatus;
var
  I: byte;
  Reloaded: boolean;
  Payroll, Cost: longint;

begin
  Game.PicturePage := 32768;
  if Game.TownPictureLoaded then
  begin
    Game.PictureFileName := 'STATUS.PIC';
    LoadScreenPicture;
    Game.TownPictureLoaded := false;
    Reloaded := true;
  end
  else Reloaded := false;
  SetVideoPage(1);
  HeaderPrompt(6);
  Payroll := 0;

  for I := 2 to 5 do
    if Game.Relics[I].Owned then DrawPictureTile(HeroRelicPositions[I], Game.Relics[I].Artwork);
  for I := 0 to 9 do
    if Game.Army[I].Species < 100 then
    begin
      Cost := CreatureDefinitions[Game.Army[I].Species].Cost.Price;
      Cost := Cost * Game.Army[I].Count div 20;
      Payroll := Payroll + Cost;
    end;

  Str(Game.Leadership + Game.LeadershipBonus: 5, Game.TextBuffer);
  DrawText(false, 67, 30, Game.TextBuffer);
  Str(Game.Gold: 8, Game.TextBuffer);
  DrawText(false, 64, 50, Game.TextBuffer);
  Str(Game.Income: 6, Game.TextBuffer);
  DrawText(false, 66, 60, Game.TextBuffer);
  Str(Payroll: 6, Game.TextBuffer);
  DrawText(false, 66, 70, Game.TextBuffer);
  Str(Game.MagicPower: 3, Game.TextBuffer);
  DrawText(false, 69, 90, Game.TextBuffer);
  Str(Game.ScrollCapacity: 3, Game.TextBuffer);
  DrawText(false, 69, 100, Game.TextBuffer);
  Str(Game.TornadoCharges: 3, Game.TextBuffer);
  DrawText(false, 69, 120, Game.TextBuffer);
  Str(Game.MapParts: 3, Game.TextBuffer);
  DrawText(false, 69, 130, Game.TextBuffer);
  Game.LastScan := ReadScanCode;
  SetVideoPage(0);

  if Reloaded then LoadResourceFile(Game.PictureBanks[4], Game.IslandPictureFileName);
  Game.PicturePage := 0;
end;

procedure RitualSpellReport;
var
  I, Row: byte;

begin
  if CountRitualSpells > 0 then
  begin
    DrawDialog(8, 230, 488, 321);
    HeaderPrompt(6);
    Row := 0;
    DrawText(false, 2, 240, 'ЗАКЛИНАНИЯ');

    for I := 0 to 7 do
      if Game.SpellAvailable[I] then
      begin
        DrawText(false, 2, Row * 8 + 256, Game.SpellTitles[I]);

        if Game.SpellUsed[I] then DrawText(false, 15, Row * 8 + 256, SpellEffects[I]);
        Inc(Row);
      end;

    Game.LastScan := ReadScanCode;
  end;
end;

procedure CastTornado;
var
  X, Y, Slot, Mask, X0, Y0: byte;

begin
  if Game.TornadoCharges > 0 then
  begin
    X0 := Game.Hero.X - 2;
    Y0 := Game.Hero.Y - 2;
    Dec(Game.TornadoCharges);
    Mask := 1;

    repeat
      for X := X0 to X0 + 4 do
        for Y := Y0 to Y0 + 4 do
          DrawMaskedTile(BattleCellOffsets[(Y - Y0) * 6 + (X - X0)], Game.Map[Game.Island, X, Y], Mask);
      Mask := Mask shl 1;
    until Mask = 16;

    for X := X0 to X0 + 4 do
      for Y := Y0 to Y0 + 4 do
        case Game.Map[Game.Island, X, Y] of
          5: begin
            Slot := FindWanderingArmy(X, Y);
            Game.Map[Game.Island, X, Y] := 0;
            RelocateArmy(Game.Island, Slot);
          end;

          28: begin
            byte(Game.MageAge) := 0;
            Game.Map[Game.Island, Game.MagePosition.X, Game.MagePosition.Y] := 0;
            PlaceRoamingObject(Game.Island, 28, Game.MagePosition);
          end;
        end;
  end
  else ShowNotice(24);
end;

procedure CargoReport;
var
  I: byte;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 17, 240, '#     Макс.цена(#1)');

  for I := 1 to 7 do
  begin
    DrawText(false, 5,(I - 1) * 8 + 256, GoodsNames[I]);
    Str(I, Game.TextBuffer);
    Game.TextBuffer := Game.TextBuffer + ')';
    DrawText(false, 2,(I - 1) * 8 + 256, Game.TextBuffer);
    Str(Game.Cargo[I]: 3, Game.TextBuffer);
    DrawText(false, 16,(I - 1) * 8 + 256, Game.TextBuffer);
    Str(Game.CargoMaxPrices[I]: 3, Game.TextBuffer);
    DrawText(false, 28,(I - 1) * 8 + 256, Game.TextBuffer);
  end;

  Game.LastScan := Ord(ReadKey);
  HeaderPrompt(0);
end;

procedure CurrentContract;
begin
  if Game.ContractIsland < 6 then
  begin
    ContractReport(Game.Contracts[Game.ContractIsland, Game.ContractSlot].Island,
      Game.Contracts[Game.ContractIsland, Game.ContractSlot].Slot);
    Game.LastScan := Ord(ReadKey);
  end
  else ShowNotice(8);
end;

procedure SeaVoyage;
label
  ChooseIsland, Finished;

var
  X, Y, Island: byte;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 256, '1) Рaвнолесье');

  if Game.UnlockedIslands > 1 then DrawText(false, 2, 264, '2) Заболотия');
  if Game.UnlockedIslands > 2 then DrawText(false, 2, 272, '3) Тайгания');
  if Game.UnlockedIslands > 3 then DrawText(false, 2, 280, '4) Альпия');

  if Game.UnlockedIslands > 4 then DrawText(false, 2, 288, '5) Сахаpия');
  if (Game.MapParts > 4) and (Game.Difficulty = 3) then DrawText(false, 2, 296, '6) Мальгpимия');
ChooseIsland:
  repeat
    Game.LastScan := Ord(ReadKey)
  until (Game.LastScan in [49..54]) or (Game.LastScan = 27);

  if Game.LastScan = 27 then goto Finished;
  if (Game.MapParts > 4) and (Game.LastScan = 54) and (Game.Difficulty = 3) then FirstSeriesEnding;
  Val(Chr(Game.LastScan), Island, Game.GenerationLimit);

  if Game.UnlockedIslands < Island then goto ChooseIsland;
  EnterIsland(Island);
  if Island = 5 then
    for X := 3 to 65 do
      for Y := 3 to 65 do
        if Game.Map[5, X, Y] = 4 then
        begin
          Game.ShoreTile := 32;

          if (Game.Map[5, X, Y - 1] > 31) and (Game.Map[5, X, Y - 1] < 48) then Inc(Game.ShoreTile, 1);
          if (Game.Map[5, X, Y + 1] > 31) and (Game.Map[5, X, Y + 1] < 48) then Inc(Game.ShoreTile, 2);
          if (Game.Map[5, X - 1, Y] > 31) and (Game.Map[5, X - 1, Y] < 48) then Inc(Game.ShoreTile, 4);

          if (Game.Map[5, X + 1, Y] > 31) and (Game.Map[5, X + 1, Y] < 48) then Inc(Game.ShoreTile, 8);
          Game.Map[5, X, Y] := Game.ShoreTile;
        end;

  if Game.ExtraDays = 0 then Game.Days := 1;
  Game.Hero.X := 3;
  Game.Hero.Y := 3;
Finished:
end;

procedure AdventureHelp;
begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, '( A ) обход своей аpмии');
  DrawText(false, 2, 248, '( B ) пpосмотpеть товаp');
  DrawText(false, 2, 256, '( C ) поиск заклинания');
  DrawText(false, 2, 264, '( D ) отпустить воинов');
  DrawText(false, 2, 272, '( E ) закончить неделю');
  Game.TextBuffer := '( F ) ' + SoundToggleCaptions[shortint(Game.SoundDisabled)] + ' звук';
  DrawText(false, 2, 280, Game.TextBuffer);
  DrawText(false, 2, 288, '( G ) "Автоpа!"');
  DrawText(false, 2, 296, '( I ) вспомнить договоp');
  DrawText(false, 2, 304, '( M ) каpта местности');
  DrawText(false, 30, 240, '( N ) дpугой континент');
  DrawText(false, 30, 248, '( P ) pекламная пауза');
  DrawText(false, 30, 256, '( S ) запись игpы');
  DrawText(false, 30, 264, '( T ) вызвать смеpч');
  DrawText(false, 30, 272, '( U ) волшебство');
  DrawText(false, 30, 280, '( V ) текущий статус');
  DrawText(false, 30, 288, '( W ) вызов pаботников');

  if CountRitualSpells > 0 then DrawText(false, 30, 296, '( R ) пpосмотpеть заклинания');
  Game.LastScan := Ord(ReadKey);
  HeaderPrompt(0);
end;



procedure SandLanding;
begin
  EncounterLanding;
  if Game.ExtraDays > 0 then
  begin
    Game.ExtraDays := 0;
    DrawTime
  end
  else if Game.Days > 29 then Dec(Game.Days, 29)
  else Game.Days := 1;
end;

procedure PrepareLoadedCampaign;
label
  SpiritFound;

var
  I, J: byte;
  UnknownLocal: word;
  Count: byte;
  Positions: array[1..2] of TPosition;

begin
  PlaceRoamingObject(Game.Island, 12, Game.WizardPosition);
  PlaceRoamingObject(Game.Island, 28, Game.MagePosition);

  for I := 25 to 29 do
  begin
    CreatureDefinitions[I] := Game.Mutants[I];
    J := CreatureDefinitions[I].Cost.Price shr 8;
    LoadCreatureArt(J);
    CopyRecord(0, 0, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
    StoreMutantFrames(I - 25, 0);
  end;

  for I := 0 to 4 do
    if Game.Army[I].Species < 100 then
    begin
      LoadCreatureArt(Game.Army[I].Species);
      CopyRecord(0, I, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
    end;

  Count := 0;
  for I := 5 to 60 do
    for J := 5 to 60 do
      if Game.Map[Game.Island, I, J] = 9 then
      begin
        Inc(Count);
        Positions[Count].X := I;
        Positions[Count].Y := J;
        Game.Map[Game.Island, I, J] := 0;
      end;

  while Count > 0 do
  begin
    repeat
      I := Random(65);
      J := Random(65)
    until Game.Map[Game.Island, I, J] = 0;
    Game.Map[Game.Island, I, J] := 9;
    Dec(Count);
  end;

  for J := 3 to 65 do
    for I := 3 to 65 do
      if Game.Map[5, I, J] = 22 then
      begin
        Game.SpiritStonePosition.X := I;
        Game.SpiritStonePosition.Y := J;
        goto SpiritFound;
      end;

SpiritFound:
  for I := 0 to 7 do Game.SpellTitles[I] := SpellColors[Game.SpellColors[I]];
  if Game.ShipOwned then ComposeTile(Game.ShipBackground);
  RefreshRoamingArmyArt;
  Game.TimeStopAccumulated := Game.ExtraDays;
  Game.Heading := true;
  Game.ShipHeading := 1;
end;

procedure SaveNamedGame;
var
  Length: byte;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 14, 256, 'Введите имя файла (8 символов):');
  Game.DataFileName := '';
  Length := 0;

  repeat
    repeat
      Game.LastScan := Ord(ReadKey)
    until Game.LastScan <> 0;

    if Game.LastScan = 8 then
    begin
      if Length > 0 then
      begin
        Dec(Length);
        DrawText(false, Length + 26, 272, ' ');

        if Length > 0 then Game.DataFileName := Copy(Game.DataFileName, 1, Length)
        else Game.DataFileName := '';
      end;
    end
    else if Game.LastScan > 47 then
    begin
      Game.DataFileName := Concat(Game.DataFileName, Chr(Game.LastScan));
      Inc(Length);
      DrawText(false, 26, 272, Game.DataFileName);
    end;
  until (Game.LastScan = 13) or (Game.LastScan = 27) or (Length = 8);

  if (Game.LastScan = 27) or (Game.DataFileName = '') then
  begin
  end
  else
  begin
    Game.DataFileName := Game.DataFileName + '.KB2';
    PrepareSave;
    WriteCampaign;
  end;
end;

procedure RitualGuardianVisit;
var
  UnknownLocal: byte;
  Text: string[30];

begin
  if ArmyReport(TReportSpecies(Game.GuardianSpecies), TReportCounts(Game.GuardianCounts), ' ') then;
  DrawText(false, 14, 304, 'Дpаться будешь ( Y-да / N-нет ) ?');
  Game.LastScan := ReadScanCode;

  if Game.LastScan = 21 then
    if Game.ArmyAvailable then
    begin
      Battle(@Game.GuardianSpecies, @Game.GuardianCounts, 8);

      if Game.BattleResult = 2 then
      begin
        Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 0;
        Game.HiddenSpellIsland := 100;
      end
      else
      begin
        DrawDialog(8, 230, 488, 320);
        Text := 'Вы нашли ' + Game.SpellTitles[Game.HiddenSpellEffect] + ' заклинание.';
        DrawText(false, 13, 264, Text);
        Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 0;
        Game.SpellAvailable[Game.HiddenSpellEffect] := true;
        Game.HiddenSpellIsland := 100;

        if CountRitualSpells = 1 then Game.InstructionsShown := false;
        Game.LastScan := ReadScanCode;
      end;

      RestoreControls;
    end
    else
    begin
      Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 0;
      Game.HiddenSpellIsland := 100;
    end;
end;

procedure Credits;
begin
  DrawDialog(8, 210, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 24, 220, 'ИНФОРМАЦИЯ О ИГРЕ');
  DrawText(false, 2, 240, 'Игpа КВ2, веpс.1.00');
  DrawText(false, 2, 250, 'По мотивам King"s Bounti, New World Computing, Inc.');
  DrawText(false, 2, 270, 'Сделал : Сеpгей Пpокофьев.');
  DrawText(false, 2, 280, 'Отладил: Андpей Сало (ДЕД).');
  DrawText(false, 2, 290, AuthorContact);
  DrawText(false, 2, 306, 'Пpимечание: Клавиши "Начальник идет" нет.');
  Game.LastScan := ReadScanCode;
end;

procedure RegrowMountain;
var
  Slot: byte;

begin
  Dec(Game.RegrowthCountdown);
  if Game.RegrowthCountdown = 0 then
    if (Game.RegrowthPosition.X = Game.GenerationX)
      and (Game.RegrowthPosition.Y = Game.GenerationY) then Inc(Game.RegrowthCountdown)
    else
    begin
      if Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y] = 14 then AbandonShip;

      if Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y] = 5 then
      begin
        Slot := FindWanderingArmy(Game.RegrowthPosition.X, Game.RegrowthPosition.Y);
        Game.WanderingArmies[5, Slot].X := 255;
      end;

      Game.ShoreTile := 80;
      if (Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y - 1] > 79)
        and (Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y - 1] < 96) then
      begin
        Inc(Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y - 1], 2);
        Inc(Game.ShoreTile, 1);
      end;

      if (Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y + 1] > 79)
        and (Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y + 1] < 96) then
      begin
        Inc(Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y + 1], 1);
        Inc(Game.ShoreTile, 2);
      end;

      if (Game.Map[5, Game.RegrowthPosition.X - 1, Game.RegrowthPosition.Y] > 79)
        and (Game.Map[5, Game.RegrowthPosition.X - 1, Game.RegrowthPosition.Y] < 96) then
      begin
        Inc(Game.Map[5, Game.RegrowthPosition.X - 1, Game.RegrowthPosition.Y], 8);
        Inc(Game.ShoreTile, 4);
      end;

      if (Game.Map[5, Game.RegrowthPosition.X + 1, Game.RegrowthPosition.Y] > 79)
        and (Game.Map[5, Game.RegrowthPosition.X + 1, Game.RegrowthPosition.Y] < 96) then
      begin
        Inc(Game.Map[5, Game.RegrowthPosition.X + 1, Game.RegrowthPosition.Y], 4);
        Inc(Game.ShoreTile, 8);
      end;

      Game.Map[5, Game.RegrowthPosition.X, Game.RegrowthPosition.Y] := Game.ShoreTile;
      Game.RegrowthPosition.X := 100;
    end;
end;

procedure RunGame;
label
  AdventureLoop, InputReady;

begin
  Game.CachedCreatureId := 100;
  SetGraphicsMode(1);
  InitializeRuntime;
  LoadTitle;
  StartupMenu;
  LoadGameArtwork;
  RefreshDwellings;
  PrepareLoadedCampaign;
  RestoreControls;
AdventureLoop:
  DrawAdventureField;
  Game.ActionScratch := Game.MagicPower;

  while not KeyPressed do
  begin
    if Game.Gold > 999999 then
    begin
      Game.WealthPicture := Random(39) div 10 + 128;
      DrawPictureTile(16222, Game.WealthPicture);
    end;

    if Game.IdlePowerPhase > 0 then
    begin
      Game.MagicPower := Random(shortint(Game.ActionScratch) * 2 + 1) shr 1;
      RefreshMagic;
      Game.IdlePowerPhase := 0;
    end
    else Inc(Game.IdlePowerPhase);

    for Game.IdleCounter := 1 to 200 do
      if KeyPressed then goto InputReady
      else Delay(2);
  end;

InputReady:
  Game.MagicPower := Game.ActionScratch;
  RevealNearbyTiles;
  MoveRoamer(Game.Island, 12, Game.WizardPosition);
  Game.GenerationX := Game.Hero.X;
  Game.GenerationY := Game.Hero.Y;
  Game.LastScan := ReadScanCode;

  case Game.LastScan of
    68: begin
    end;

    71: if (Game.GenerationX > 2) and (Game.GenerationY > 2) then
    begin
      Dec(Game.GenerationX);
      Dec(Game.GenerationY)
    end;

    72: if Game.GenerationY > 2 then Dec(Game.GenerationY);
    73: if (Game.GenerationX < 63) and (Game.GenerationY > 2) then
    begin
      Inc(Game.GenerationX);
      Dec(Game.GenerationY)
    end;

    75: if Game.GenerationX > 2 then Dec(Game.GenerationX);
    77: if Game.GenerationX < 63 then Inc(Game.GenerationX);
    79: if (Game.GenerationX > 2) and (Game.GenerationY < 63) then
    begin
      Dec(Game.GenerationX);
      Inc(Game.GenerationY)
    end;

    80: if Game.GenerationY < 63 then Inc(Game.GenerationY);
    81: if (Game.GenerationX < 63) and (Game.GenerationY < 63) then
    begin
      Inc(Game.GenerationX);
      Inc(Game.GenerationY)
    end;

    17: WorkersMenu(Game.Island);
    18: begin
      Game.ExtraDays := 0;
      Game.Days := 1
    end;

    19: RitualSpellReport;
    20: CastTornado;
    22: if not Game.ShipAbandonBlocked then AdventureMagic;
    23: CurrentContract;
    24: AdventureHelp;
    25: ShowNotice(20);
    30: ArmyOverview;
    31: if not Game.ShipAbandonBlocked then
    begin
      PrepareSave;
      WriteCampaign;
      ShowNotice(23)
    end;

    32: DismissArmy;
    33: Game.SoundDisabled := not Game.SoundDisabled;
    34: Credits;
    46: SearchRitualSpell;
    47: HeroStatus;
    48: CargoReport;
    49: if Game.ShipAbandonBlocked then SeaVoyage;
    50: MapVisit(Game.Island);
  else Game.LastScan := 71;
  end;

  if (Game.LastScan in [71, 75, 79]) and not Game.Heading then
  begin
    if Game.ShipAbandonBlocked then MirrorTileArt(15)
    else MirrorTileArt(6);
    Game.Heading := true;
  end
  else if (Game.LastScan in [73, 77, 81]) and Game.Heading then
  begin
    if Game.ShipAbandonBlocked then MirrorTileArt(15)
    else MirrorTileArt(6);
    Game.Heading := false;
  end;

  if Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] >= 64 then
  begin
    Sound(200);
    Delay(30);
    NoSound;
    Game.GenerationX := Game.Hero.X;
    Game.GenerationY := Game.Hero.Y;
  end
  else
  begin
    Sound(600);
    Delay(2);
    NoSound;
    Inc(Game.GoodsMarketAge);
  end;

  if Game.RegrowthCountdown > 0 then RegrowMountain;
  if Game.LastScan > 70 then
  begin
    Game.ActionScratch := Game.EnemyGrace;
    AdvanceNearbyRoamers;

    if Game.WorldMapPending <> 0 then MoveRoamer(Game.Island, 28, Game.MagePosition);
    if (shortint(Game.ActionScratch) > 0) and (Game.EnemyGrace = 0) then
      CopyRecord(0, 5, 2880, Game.PictureBanks[13], Game.PictureBanks[0]);
    case Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] of
      32..47: SandLanding;
      48..63: if Game.ShipAbandonBlocked then
      begin
        Game.Hero.X := Game.GenerationX;
        Game.Hero.Y := Game.GenerationY
      end;

      2: CastleVisit;
      18: CastleVisit;
      4: begin
        Game.Hero.X := Game.GenerationX;
        Game.Hero.Y := Game.GenerationY
      end;

      7: TownVisit;
      8: DwellingVisit;
      5: WanderingArmyVisit;
      9: PaperScrollVisit;
      10: TreasureVisit;
      11: begin
        UndergroundVisit;
        Game.Hero.X := Game.GenerationX;
        Game.Hero.Y := Game.GenerationY
      end;

      12: WizardVisit;
      28: BlackMage;
      22: TalkingStoneVisit;
      23: RitualGuardianVisit;
      14: BoardShip;
      0: EncounterLanding;
    end;
  end;

  if Game.ExtraDays > 0 then
  begin
    Dec(Game.ExtraDays);
    DrawTime
  end
  else
  begin
    Dec(Game.Days);

    if Game.Days = 0 then EndWeek;
  end;

  if Game.LastScan <> 68 then goto AdventureLoop;
  ShowNotice(13);
  if Game.LastScan <> 21 then goto AdventureLoop;

  if not Game.ShipAbandonBlocked then
  begin
    ShowNotice(15);

    if Game.LastScan = 21 then SaveNamedGame;
  end;

  CleanupGame;
end;
end.
