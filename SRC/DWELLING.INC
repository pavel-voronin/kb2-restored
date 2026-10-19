procedure DwellingVisit;
label
  FreeSlot, ContinueLoop, Finished;

const
  GoldCaption = 'Деньги: $';
  StockPriceCaption = 'Имеется:      Стоимость: $';
  HireCaption = 'Вы можете нанять:';
  MovementCaption = 'Движение:';
  DefenseCaption = 'Защита  :';
  AttackCaption = 'Удаp    :';
  FlightCaption = 'Летает? :';
  YesCaption = 'Да';
  NoCaption = 'Нет';

var
  DwellingIndex, ArmyIndex: shortint;
  Limit: word;

procedure BuyExisting;
begin
  if Game.Army[ArmyIndex].Count > Limit then Limit := Game.Army[ArmyIndex].Count;
  Limit := Limit - Game.Army[ArmyIndex].Count;
  Str(Limit, Game.TextBuffer);
  DrawText(false, 54, 280, Game.TextBuffer);
  BuyQuantity(Limit, CreatureDefinitions[Game.Army[ArmyIndex].Species].Cost.Price, Game.Army[ArmyIndex].Count,
    Game.Dwellings[Game.Island, DwellingIndex].Count);
end;

begin
  DwellingIndex := -1;
  repeat
    Inc(DwellingIndex)
  until (Game.Dwellings[Game.Island, DwellingIndex].X = Game.GenerationX) and
    (Game.Dwellings[Game.Island, DwellingIndex].Y = Game.GenerationY);
  if Game.Dwellings[Game.Island, DwellingIndex].Species <> Game.CachedCreatureId then
    LoadCreatureArt(Game.Dwellings[Game.Island, DwellingIndex].Species);
  DrawTile(BattleCellOffsets[14], Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y], 96);

  repeat
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 2, 240, CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Name);
    DrawText(false, 42, 240, GoldCaption);
    Str(Game.Gold, Game.TextBuffer);
    DrawText(false, 51, 240, Game.TextBuffer);
    DrawText(false, 2, 256, StockPriceCaption);
    DrawText(false, 36, 280, HireCaption);
    DrawText(false, 2, 280, MovementCaption);
    DrawText(false, 2, 288, DefenseCaption);
    DrawText(false, 2, 296, AttackCaption);
    DrawText(false, 2, 304, FlightCaption);
    Str(Game.Dwellings[Game.Island, DwellingIndex].Count, Game.TextBuffer);
    DrawText(false, 11, 256, Game.TextBuffer);
    Str(CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Cost.Price, Game.TextBuffer);
    DrawText(false, 28, 256, Game.TextBuffer);
    Str(CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Movement, Game.TextBuffer);
    DrawText(false, 12, 280, Game.TextBuffer);
    Str(CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Defense, Game.TextBuffer);
    DrawText(false, 12, 288, Game.TextBuffer);
    Str(CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Attack, Game.TextBuffer);
    DrawText(false, 12, 296, Game.TextBuffer);

    if CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Flags and 128 = 128 then
      DrawText(false, 12, 304, YesCaption)
      else DrawText(false, 12, 304, NoCaption);
    Limit := (Game.Leadership + Game.LeadershipBonus) div
      CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Defense;
    for ArmyIndex := 0 to 9 do
      if Game.Army[ArmyIndex].Species = Game.Dwellings[Game.Island, DwellingIndex].Species then
      begin
        BuyExisting;
        goto ContinueLoop;
      end;

    for ArmyIndex := 0 to 9 do if Game.Army[ArmyIndex].Species = 100 then goto FreeSlot;
    ShowNotice(6);
    goto Finished;
FreeSlot:
    Str(Limit, Game.TextBuffer);
    DrawText(false, 54, 280, Game.TextBuffer);
    Game.Army[ArmyIndex].Count := 0;
    BuyQuantity(Limit, CreatureDefinitions[Game.Dwellings[Game.Island, DwellingIndex].Species].Cost.Price,
      Game.Army[ArmyIndex].Count, Game.Dwellings[Game.Island, DwellingIndex].Count);

    if Game.LastScan = 27 then goto Finished;
    if Game.EnemyGrace > 0 then CopyRecord(0, 5, 2880, Game.PictureBanks[13], Game.PictureBanks[0]);
    Game.ArmyAvailable := true;
    Game.EnemyGrace := 0;
    Game.Army[ArmyIndex].Species := Game.Dwellings[Game.Island, DwellingIndex].Species;

    if ArmyIndex < 5 then CopyRecord(0, ArmyIndex, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
ContinueLoop:
  until Game.LastScan = 27;
Finished:
  HeaderPrompt(0);
end;
