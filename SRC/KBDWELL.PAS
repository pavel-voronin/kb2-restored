unit KBDwell;
{$G+,R-,S-,I+,A+}

interface

procedure DwellingVisit;

implementation

uses KBEcon, KBTables, KBUI, KBArt, KBGfx, KBFiles, Crt, KBState;

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
  if Game.Campaign.Army[ArmyIndex].Count > Limit then Limit := Game.Campaign.Army[ArmyIndex].Count;
  Limit := Limit - Game.Campaign.Army[ArmyIndex].Count;
  Str(Limit, Game.Runtime.TextBuffer);
  DrawText(false, 54, 280, Game.Runtime.TextBuffer);
  BuyQuantity(Limit, CreatureDefinitions[Game.Campaign.Army[ArmyIndex].Species].Cost.Price,
    Game.Campaign.Army[ArmyIndex].Count,
    Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Count);
end;

begin
  DwellingIndex := -1;
  repeat
    Inc(DwellingIndex)
  until (Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].X = Game.World.GenerationX) and
    (Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Y = Game.World.GenerationY);
  if Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species <> Game.Runtime.CachedCreatureId then
    LoadCreatureArt(Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species);
  DrawTile(BattleCellOffsets[14], Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X,
    Game.Campaign.Hero.Y], 96);

  repeat
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 2, 240, CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island,
    DwellingIndex].Species].Name);
    DrawText(false, 42, 240, GoldCaption);
    Str(Game.Campaign.Gold, Game.Runtime.TextBuffer);
    DrawText(false, 51, 240, Game.Runtime.TextBuffer);
    DrawText(false, 2, 256, StockPriceCaption);
    DrawText(false, 36, 280, HireCaption);
    DrawText(false, 2, 280, MovementCaption);
    DrawText(false, 2, 288, DefenseCaption);
    DrawText(false, 2, 296, AttackCaption);
    DrawText(false, 2, 304, FlightCaption);
    Str(Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Count, Game.Runtime.TextBuffer);
    DrawText(false, 11, 256, Game.Runtime.TextBuffer);
    Str(CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Cost.Price,
    Game.Runtime.TextBuffer);
    DrawText(false, 28, 256, Game.Runtime.TextBuffer);
    Str(CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Movement,
    Game.Runtime.TextBuffer);
    DrawText(false, 12, 280, Game.Runtime.TextBuffer);
    Str(CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Defense,
    Game.Runtime.TextBuffer);
    DrawText(false, 12, 288, Game.Runtime.TextBuffer);
    Str(CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Attack,
    Game.Runtime.TextBuffer);
    DrawText(false, 12, 296, Game.Runtime.TextBuffer);

    if CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Flags and 128 =
    128 then
      DrawText(false, 12, 304, YesCaption)
      else DrawText(false, 12, 304, NoCaption);
    Limit := (Game.Campaign.Leadership + Game.Campaign.LeadershipBonus) div
      CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species].Defense;
    for ArmyIndex := 0 to 9 do
      if Game.Campaign.Army[ArmyIndex].Species = Game.Campaign.Dwellings[Game.Campaign.Island,
    DwellingIndex].Species then
      begin
        BuyExisting;
        goto ContinueLoop;
      end;

    for ArmyIndex := 0 to 9 do if Game.Campaign.Army[ArmyIndex].Species = 100 then goto FreeSlot;
    ShowNotice(6);
    goto Finished;
FreeSlot:
    Str(Limit, Game.Runtime.TextBuffer);
    DrawText(false, 54, 280, Game.Runtime.TextBuffer);
    Game.Campaign.Army[ArmyIndex].Count := 0;
    BuyQuantity(Limit, CreatureDefinitions[Game.Campaign.Dwellings[Game.Campaign.Island,
    DwellingIndex].Species].Cost.Price,
      Game.Campaign.Army[ArmyIndex].Count, Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Count);

    if Game.Runtime.LastScan = 27 then goto Finished;
    if Game.Campaign.EnemyGrace > 0 then CopyRecord(0, 5, 2880, Game.Runtime.PictureBanks[13],
    Game.Runtime.PictureBanks[0]);
    Game.Campaign.Flags.ArmyAvailable := true;
    Game.Campaign.EnemyGrace := 0;
    Game.Campaign.Army[ArmyIndex].Species := Game.Campaign.Dwellings[Game.Campaign.Island, DwellingIndex].Species;

    if ArmyIndex < 5 then CopyRecord(0, ArmyIndex, 8640, Game.Runtime.PictureBanks[11],
    Game.Runtime.PictureBanks[10]);
ContinueLoop:
  until Game.Runtime.LastScan = 27;
Finished:
  HeaderPrompt(0);
end;

end.
