unit KBAdvent;
{$G+,R-,S-,I+,A+}

interface

uses KBState;

type
  PRoamingActor = ^TRoamingActor;
  TRoamingActor = packed record
    X, Y, Age: byte
  end;

  TReportSpecies = array[0..4] of byte;
  TReportCounts = array[0..4] of word;
  TTownVisitState = packed record
    Caption: string[80];
    LoadedTownArtwork: boolean;
    Slot: byte;
    JournalIndex: shortint;
  end;

procedure ContractReport(Island, Slot: byte);

function ArmyReport(Species: TReportSpecies; Counts: TReportCounts; Caption: string): boolean;

function CountRitualSpells: byte;

procedure PlaceHiddenSpell;

procedure RefreshMagic;

procedure RefreshGold;

function PaymentFailed(Cost: longint): boolean;

procedure BuyQuantity(Capacity, Price: word; var Destination, Stock: word);

procedure BuyByteQuantity(Capacity, Price: word; var Destination: word; var Stock: byte);

procedure RandomHeroLanding;

procedure AbandonShip;

procedure TransmuteDwellings(Island: byte);

procedure RefreshRoamingArmyArt;

procedure TownVisit;

procedure RefreshDwellings;

procedure RefreshMapParts;

procedure DrawIslandName(Island, X: byte; Y: word);

procedure MoveRoamer(Island, Tile: byte; var Position: TPosition);

procedure WizardVisit;

procedure EncounterLanding;

procedure PaperScrollVisit;

procedure DwellingVisit;

procedure MapVisit(Island: byte);

implementation

uses KBGfx, KBTables, KBBattle, KBWorld, KBSound, Crt;

function CountRitualSpells: byte;
var
  I, Count: byte;

begin
  Count := 0;
  for I := 0 to 7 do if Game.SpellAvailable[I] then Inc(Count);
  CountRitualSpells := Count;
end;

procedure PlaceHiddenSpell;
begin
  if CountRitualSpells < 8 then
  begin
    Game.HiddenSpellIsland := Random(49) div 10 + 1;

    repeat
      Game.HiddenSpellPosition.X := Random(65);
      Game.HiddenSpellPosition.Y := Random(65);
    until (Game.Map[Game.HiddenSpellIsland, Game.HiddenSpellPosition.X, Game.HiddenSpellPosition.Y] = 0)
      or (Game.Map[Game.HiddenSpellIsland, Game.HiddenSpellPosition.X, Game.HiddenSpellPosition.Y] > 64);
    repeat
      Game.HiddenSpellEffect := Random(79) div 10
    until not Game.SpellAvailable[Game.HiddenSpellEffect];
  end;
end;

procedure RefreshMagic;
begin
  if (Game.MagicPower > 9) and (Game.HiddenSpellIsland = 100) then PlaceHiddenSpell;
  case Game.MagicPower of
    0: begin
      ClearPicturePlanes(11422, 7);
      DrawPicturePlanes(11422, 19, 8)
    end;

    1..2: begin
      ClearPicturePlanes(11422, 13);
      DrawPicturePlanes(11422, 19, 2)
    end;

    3..4: begin
      ClearPicturePlanes(11422, 3);
      DrawPicturePlanes(11422, 19, 12)
    end;

    5..6: begin
      ClearPicturePlanes(11422, 12);
      DrawPicturePlanes(11422, 19, 3)
    end;

    7..8: begin
      ClearPicturePlanes(11422, 9);
      DrawPicturePlanes(11422, 19, 6)
    end;

    9..10: begin
      ClearPicturePlanes(11422, 8);
      DrawPicturePlanes(11422, 19, 7)
    end;

    11..12: begin
      ClearPicturePlanes(11422, 6);
      DrawPicturePlanes(11422, 19, 9)
    end;

    13..14: begin
      ClearPicturePlanes(11422, 2);
      DrawPicturePlanes(11422, 19, 13)
    end;

    15..16: begin
      ClearPicturePlanes(11422, 5);
      DrawPicturePlanes(11422, 19, 10)
    end;

    17..18: begin
      ClearPicturePlanes(11422, 1);
      DrawPicturePlanes(11422, 19, 14)
    end;

    19..20: begin
      ClearPicturePlanes(11422, 4);
      DrawPicturePlanes(11422, 19, 11)
    end;
  else DrawPictureTile(11422, 19);
  end;
end;

procedure RefreshGold;
begin
  if Game.Gold < 2000 then
  begin
    ClearPicturePlanes(16222, 7);
    DrawPicturePlanes(16222, 21, 8)
  end
  else if Game.Gold < 5000 then
  begin
    ClearPicturePlanes(16222, 14);
    DrawPicturePlanes(16222, 21, 1)
  end
  else if Game.Gold < 10000 then
  begin
    ClearPicturePlanes(16222, 6);
    DrawPicturePlanes(16222, 21, 9)
  end
  else if Game.Gold < 20000 then
  begin
    ClearPicturePlanes(16222, 13);
    DrawPicturePlanes(16222, 21, 2)
  end
  else if Game.Gold < 50000 then
  begin
    ClearPicturePlanes(16222, 12);
    DrawPicturePlanes(16222, 21, 3)
  end
  else if Game.Gold < 75000 then
  begin
    ClearPicturePlanes(16222, 5);
    DrawPicturePlanes(16222, 21, 10)
  end
  else if Game.Gold < 100000 then
  begin
    ClearPicturePlanes(16222, 4);
    DrawPicturePlanes(16222, 21, 11)
  end
  else if Game.Gold < 150000 then
  begin
    ClearPicturePlanes(16222, 8);
    DrawPicturePlanes(16222, 21, 7)
  end
  else if Game.Gold < 200000 then
  begin
    ClearPicturePlanes(16222, 3);
    DrawPicturePlanes(16222, 21, 12)
  end
  else if Game.Gold < 500000 then
  begin
    ClearPicturePlanes(16222, 2);
    DrawPicturePlanes(16222, 21, 13)
  end
  else if Game.Gold < 800000 then
  begin
    ClearPicturePlanes(16222, 1);
    DrawPicturePlanes(16222, 21, 14)
  end
  else DrawPictureTile(16222, 21);
end;

function PaymentFailed(Cost: longint): boolean;
var
  Page: word;

begin
  if Game.Gold >= Cost then
  begin
    Game.Gold := Game.Gold - Cost;
    PaymentFailed := false;
    Page := Game.PicturePage;
    Game.PicturePage := 0;
    RefreshGold;
    Game.PicturePage := Page;
  end
  else
  begin
    PaymentFailed := true;
    ShowNotice(1);
  end;
end;

function ReadQuantity(var Quantity: longint): boolean;

const
  Caption = 'C'#170#174#171#236#170#174'?';
  Blank = ' ';

var
  Digits: byte;

begin
  HeaderPrompt(7);
  Game.QuantityText := '';
  Digits := 0;
  DrawText(false, 45, 304, Caption);

  repeat
    Game.LastScan := Ord(ReadKey);
    case Game.LastScan of
      8: if Digits > 0 then
      begin
        Delete(Game.QuantityText, Digits, 1);
        DrawText(false, Digits + 53, 304, Blank);
        Dec(Digits);
      end;

      48..57: begin
        Game.QuantityText := Concat(Game.QuantityText, Chr(Game.LastScan));
        Inc(Digits);
        DrawText(false, 54, 304, Game.QuantityText);
      end;
    end;
  until (Game.LastScan = 13) or (Game.LastScan = 27) or (Digits > 5);
  ReadQuantity := Game.LastScan <> 27;
  Val(Game.QuantityText, Quantity, Game.GenerationCount);
end;

procedure BuyQuantity(Capacity, Price: word; var Destination, Stock: word);
var
  Quantity, Cost: longint;

begin
  if ReadQuantity(Quantity) then
    if Stock >= Quantity then
      if Capacity >= Quantity then
      begin
        if Game.Gold > 5000 then Cost := Price * Quantity
        else Cost := Random(Price * Quantity);

        if PaymentFailed(Cost) then Game.LastScan := 27
        else
        begin
          Game.CueFrequency := Cost div 10;
          PlayCue(4);
          Destination := Destination + Quantity;
          Stock := Stock - Quantity;
        end;
      end;
end;

procedure BuyByteQuantity(Capacity, Price: word; var Destination: word; var Stock: byte);
var
  Temporary: word;

begin
  Temporary := Stock;
  BuyQuantity(Capacity, Price, Destination, Temporary);
  Stock := Temporary;
end;

procedure RandomHeroLanding;
begin
  repeat
    Game.Hero.X := Random(65);
    Game.Hero.Y := Random(65);
  until Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y] = 0;
end;

procedure AbandonShip;
begin
  Game.Map[Game.ShipIsland, Game.Ship.X, Game.Ship.Y] := Game.ShipBackground;
  Game.ShipOwned := false;
end;

procedure ContractReport(Island, Slot: byte);

const
  Title = 'Контpакт';
  Target = 'Нужно взять замок:';
  Reward = 'Он оценен по контpакту в: $';

var
  Amount: longint;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 240, Title);
  DrawText(false, 2, 256, Target);
  DrawText(false, 21, 256, CastleNames[Game.Castles[Island, Slot].Name]);
  Amount := Game.Castles[Island, Slot].Value div 100;
  Str(Amount, Game.TextBuffer);
  DrawText(false, 2, 272, Reward);
  DrawText(false, 29, 272, Game.TextBuffer);
end;

function ArmyReport(Species: TReportSpecies; Counts: TReportCounts; Caption: string): boolean;
label
  Existing, Empty;

const
  FewTroops = ' : Несколько';
  SomeTroops = ' : Немного';
  ManyTroops = ' : Много';
  HordeOfTroops = ' : Толпа';
  ArmyOfTroops = ' : Аpмия';
  JoinOfferCaption = ' ';
  JoinOfferSuffix = ' хотят пpисоединиться к вашему войску.';
  AcceptTroopsPrompt = 'Вы согласны ( Y-да / N-нет ) ?';
  EmptyArmyCaption = 'Войска нет.';

var
  Rows, I: byte;
  UnknownLocal, Quantity: word;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 240, Caption);
  Rows := 0;
  I := 0;

  repeat
    if Species[I] < 100 then
    begin
      if Counts[I] < 30 then DrawText(false, 12, Rows * 8 + 256, FewTroops)
      else if Counts[I] < 100 then DrawText(false, 12, Rows * 8 + 256, SomeTroops)
      else if Counts[I] < 250 then DrawText(false, 12, Rows * 8 + 256, ManyTroops)
      else if Counts[I] < 500 then DrawText(false, 12, Rows * 8 + 256, HordeOfTroops)
      else DrawText(false, 12, Rows * 8 + 256, ArmyOfTroops);
      DrawText(false, 2, Rows * 8 + 256, CreatureDefinitions[Species[I]].Name);
      Inc(Rows);
    end;

    Inc(I);
  until I > 4;
  if Rows <= 1 then
  begin
    if Caption = JoinOfferCaption then
    begin
      Rows := Random(SummoningSpeciesLimits[Game.Island]);
      ArmyReport := true;
      Quantity := Game.Leadership div CreatureDefinitions[Rows].Defense;

      if Quantity = 0 then Quantity := 10;
      Caption := CreatureDefinitions[Rows].Name + JoinOfferSuffix;
      DrawText(false, 2, 256, Caption);
      DrawText(false, 15, 304, AcceptTroopsPrompt);
      Game.LastScan := ReadScanCode;
      Game.Map[Game.Island, Game.GenerationX, Game.GenerationY] := 0;

      if Game.LastScan = 21 then
      begin
        for I := 0 to 9 do if Game.Army[I].Species = Rows then goto Existing;

        for I := 0 to 9 do if Game.Army[I].Species = 100 then goto Empty;
        ShowNotice(6);
        Exit;
Empty:
        Game.ArmyAvailable := true;
        Game.Army[I].Species := Rows;
        Game.Army[I].Count := Quantity;

        if I < 5 then
        begin
          LoadCreatureArt(Rows);
          CopyRecord(0, I, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
        end;

        Exit;
Existing:
        Inc(Game.Army[I].Count, Quantity);
      end;
    end
    else if Rows = 0 then DrawText(false, 25, 256, EmptyArmyCaption);
  end
  else ArmyReport := false;
end;

procedure TransmuteDwellings(Island: byte);
var
  I, Species, Tier: byte;

begin
  case Game.MagicPower of
    0, 1: Exit;
    2..5: Tier := 2;
    6..10: Tier := 3;
    11..20: Tier := 4;
  else Tier := 5;
  end;

  for I := 0 to 7 do
  begin
    Species := WanderingSpeciesBases[Tier] + Random(148) div 10;

    if Species > WanderingSpeciesBases[Tier] + 9 then Dec(Species, 5);
    Game.Dwellings[Island, I].Species := Species;
    Game.Dwellings[Island, I].Count := WeeklyDwellingCapacities[Species];
  end;
end;

procedure RefreshRoamingArmyArt;
begin
  if Game.EnemyGrace > 0 then CopyRecord(0, 5, 2880, Game.CalmArmyPicture, Game.PictureBanks[0])
  else CopyRecord(0, 5, 2880, Game.PictureBanks[13], Game.PictureBanks[0]);
end;

{$I TOWN.INC}

procedure RevealDwellingRange(Minimum, Maximum: byte);
var
  I, Island: byte;

begin
  for Island := 1 to 5 do
    for I := 0 to 7 do
      if (Game.Dwellings[Island, I].Species > Minimum) and
        (Game.Dwellings[Island, I].Species < Maximum) then
        if not (Game.Map[Island, Game.Dwellings[Island, I].X, Game.Dwellings[Island, I].Y] in [1..3, 7, 18]) then
          Game.Map[Island, Game.Dwellings[Island, I].X, Game.Dwellings[Island, I].Y] := 8;
end;

procedure RefreshDwellings;
begin
  if Game.MagicPower > 10 then RevealDwellingRange(21, 25);
  if Game.MagicPower > 4 then RevealDwellingRange(19, 22);

  if Game.MagicPower > 2 then RevealDwellingRange(14, 20);
  if Game.MagicPower > 0 then RevealDwellingRange(9, 15);
  if Game.MagicPower in [1, 3, 5, 11] then PlayCue(5);
end;

procedure RefreshMapParts;
begin
  case Game.MapParts of
    0: begin
      ClearPicturePlanes(21022, 7);
      DrawPicturePlanes(21022, 20, 8)
    end;

    1: begin
      ClearPicturePlanes(21022, 3);
      DrawPicturePlanes(21022, 20, 12)
    end;

    2: begin
      ClearPicturePlanes(21022, 2);
      DrawPicturePlanes(21022, 20, 13)
    end;

    3: begin
      ClearPicturePlanes(21022, 1);
      DrawPicturePlanes(21022, 20, 14)
    end;

    4: begin
      ClearPicturePlanes(21022, 4);
      DrawPicturePlanes(21022, 20, 11)
    end;
  else DrawPictureTile(21022, 20);
  end;
end;

procedure DrawIslandName(Island, X: byte; Y: word);

const
  Name1 = 'РAВНОЛЕСЬЕ';
  Name2 = 'ЗАБОЛОТИЯ';
  Name3 = 'ТАЙГАНИЯ';
  Name4 = 'АЛЬПИЯ';
  Name5 = 'CАХАРИЯ';

begin
  case Island of
    1: DrawText(false, X, Y, Name1);
    2: DrawText(false, X, Y, Name2);
    3: DrawText(false, X, Y, Name3);
    4: DrawText(false, X, Y, Name4);
    5: DrawText(false, X, Y, Name5);
  end;
end;

procedure MoveRoamer(Island, Tile: byte; var Position: TPosition);
var
  X, Y: byte;

begin
  if PRoamingActor(@Position)^.Age > Game.Difficulty then
  begin
    PRoamingActor(@Position)^.Age := 0;
    Game.Map[Island, Position.X, Position.Y] := 0;
    PlaceRoamingObject(Island, Tile, Position);
  end
  else
  begin
    Inc(PRoamingActor(@Position)^.Age);
    X := Position.X;
    Y := Position.Y;
    Game.RoamerDirection := Random(79) div 10;

    case Game.RoamerDirection of
      0: begin
        Dec(X);
        Dec(Y)
      end;

      1: Dec(Y);
      2: begin
        Inc(X);
        Dec(Y)
      end;

      3: Inc(X);
      4: begin
        Inc(X);
        Inc(Y)
      end;

      5: Inc(Y);
      6: begin
        Dec(X);
        Inc(Y)
      end;

      7: Dec(X);
    end;

    if Game.Map[Island, X, Y] = 0 then
    begin
      Game.Map[Island, Position.X, Position.Y] := 0;
      Game.Map[Island, X, Y] := Tile;
      Position.X := X;
      Position.Y := Y;
    end;
  end;
end;

{$I WIZARD.INC}

procedure EncounterLanding;
begin
  if Game.ShipAbandonBlocked then
  begin
    Game.ShipAbandonBlocked := false;
    PlaceShip(Game.Hero.X, Game.Hero.Y);

    if Game.Heading xor boolean(Game.ShipHeading) then MirrorTileArt(6);
    Game.ShipHeading := Ord(Game.Heading);
  end;

  Game.Hero.X := Game.GenerationX;
  Game.Hero.Y := Game.GenerationY;
end;

{$I SCROLL.INC}
{$I DWELLING.INC}
{$I MAP.INC}

const
  SubjectOne = 'SUBJECT1.PIC';
  SubjectTwo = 'SUBJECT2.PIC';
  DesertPicture = 'DESERT.PIC';
  WaterPicture = 'WATER.PIC';
  WoodPicture = 'WOOD.PIC';
  MountainPicture = 'MOUNTAIN.PIC';
  EnemyPicture = 'ENEMY.PIC';
  ReservePicture = 'ARMY5.PIC';

begin
  Game.CurrentContractOffer := 1;
  Game.GoodsMarketTown := 255;
  Game.GoodsMarketIsland := 1;
  Game.ShipAbandonBlocked := false;
  Game.SubjectOneFileName := SubjectOne;
  Game.SubjectTwoFileName := SubjectTwo;
  Game.BattlePictureFileName := DesertPicture;
  Game.WaterPictureFileName := WaterPicture;
  Game.IslandPictureFileName := WoodPicture;
  Game.ChartPictureFileName := MountainPicture;
  Game.EnemyPictureFileName := EnemyPicture;
  Game.ReservePictureFileName := ReservePicture;

  for Game.InitIndex := 1 to 4 do
  begin
    Game.GenerationX := Random(20);

    if Game.GenerationX < 10 then Game.PaperChartPresent[Game.InitIndex] := false
    else Game.PaperChartPresent[Game.InitIndex] := true;
  end;

  Game.PaperChartPresent[5] := false;
  Game.SceneIsland := 1;
  Game.ShipHeading := 1;
  GetMem(Game.PictureBanks[11], 8640);
  GetMem(Game.PictureBanks[10], 43200);
  GetMem(Game.PictureBanks[12], 11520);
  GetMem(Game.PictureBanks[14], 2880);
  GetMem(Game.PictureBanks[0], 46800);
  GetMem(Game.PictureBanks[1], 46800);
  GetMem(Game.PictureBanks[2], 46800);
  GetMem(Game.PictureBanks[3], 46800);
  GetMem(Game.PictureBanks[4], 46800);
  GetMem(Game.PictureBanks[5], 46800);
  GetMem(Game.PictureBanks[13], 5760);
  asm
    mov ax, ds
    mov es, ax
    lea di, Game.PictureBanks
    add di, 24
    lea si, Game.PictureBanks[44]
    movsw
    movsw
    lea si, Game.PictureBanks[40]
    movsw
    movsw
    lea si, Game.PictureBanks[48]
    movsw
    movsw
  end;
end.
