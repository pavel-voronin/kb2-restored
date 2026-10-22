unit KBTown;
{$G+,R-,S-,I+,A+}

interface

procedure PlaceShip(X, Y: byte);
procedure TownVisit;

implementation

uses KBAdvent, KBEcon, KBHud, KBReport, KBTables, KBUI, KBGfx, KBInput, KBFiles, Crt, KBTypes, KBState;

procedure PlaceShip(X, Y: byte);
begin
  Game.Campaign.ShipIsland := Game.Campaign.Island;
  Game.Campaign.Ship.X := X;
  Game.Campaign.Ship.Y := Y;
  Game.Campaign.ShipBackground := Game.Campaign.Map[Game.Campaign.Island, X, Y];
  Game.Campaign.Map[Game.Campaign.Island, X, Y] := 14;
  ComposeTile(Game.Campaign.ShipBackground);
end;

procedure TownVisit;

const
  TownPictureName = 'TOWN.PIC';
  TownCaption = 'Гоpод';
  GoldCaption = 'Деньги: $';
  ContractMenuItem = '1) Заключить контpакт';
  CastleMenuItem = '3) Спpосить о замке';
  ScrollMenuPrefix = '4) ';
  PricePrefix = ' ($';
  PriceSuffix = ')';
  SiegeEngineMenuItem = '5) Купить стенобитное оpудие ($3000)';
  WorkersMenuItem = '6) Работники';
  GoodsMenuItem = '7) Товаp';
  CastleCaption = 'Замок ';

var
  TownState: TTownVisitState;

procedure WorkerMarket;

const
  WorkersCaption = 'РАБОТНИКИ';
  GoldCaption = 'Золото: $';
  CarpentersMenuItem = '1) Плотники ($500):';
  WoodcuttersMenuItem = '2) Лесоpубы ($500):';
  DiggersMenuItem = '3) Землекопы($800):';
  StonecuttersMenuItem = '4) Камнетесы($800):';

begin
  repeat
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 2, 240, WorkersCaption);
    DrawText(false, 42, 240, GoldCaption);
    Str(Game.Campaign.Gold, Game.Runtime.TextBuffer);
    DrawText(false, 51, 240, Game.Runtime.TextBuffer);
    DrawText(false, 2, 256, CarpentersMenuItem);
    Str(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[1], Game.Runtime.TextBuffer);
    DrawText(false, 22, 256, Game.Runtime.TextBuffer);
    DrawText(false, 2, 264, WoodcuttersMenuItem);
    Str(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[2], Game.Runtime.TextBuffer);
    DrawText(false, 22, 264, Game.Runtime.TextBuffer);
    DrawText(false, 2, 272, DiggersMenuItem);
    Str(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[4], Game.Runtime.TextBuffer);
    DrawText(false, 22, 272, Game.Runtime.TextBuffer);
    DrawText(false, 2, 280, StonecuttersMenuItem);
    Str(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[3], Game.Runtime.TextBuffer);
    DrawText(false, 22, 280, Game.Runtime.TextBuffer);
    Game.Runtime.LastScan := ReadScanCode;

    case Game.Runtime.LastScan of
      2: BuyByteQuantity(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[1], 500,
    Game.Campaign.Carpenters,
        Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[1]);
      3: BuyByteQuantity(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[2], 500,
    Game.Campaign.Woodcutters,
        Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[2]);
      4: BuyByteQuantity(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[4], 800,
    Game.Campaign.Diggers,
        Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[4]);
      5: BuyByteQuantity(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[3], 800,
    Game.Campaign.Stonecutters,
        Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Workers[3]);
    end;
  until Game.Runtime.LastScan = 1;
  HeaderPrompt(2);
  Game.Runtime.LastScan := 48;
end;

procedure BuyShip;
label
  Found;

var
  DX, DY: shortint;

begin
  if Game.Campaign.Flags.ShipOwned then
    if Game.Runtime.ShipAbandonBlocked then Exit
    else
    begin
      AbandonShip;
      Exit
    end;

  begin
    if PaymentFailed(ShipPurchasePrice) then Exit;
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if (Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].X +
    DX, Game.Campaign.Towns[Game.Campaign.Island,
          TownState.Slot].Y + DY] >= 48) and
          (Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].X + DX,
          Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Y + DY] < 64) then goto Found;
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].X + DX,
          Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Y + DY] = 4 then goto Found;
Found:
    PlaceShip(Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].X + DX,
    Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Y + DY);
    Game.Campaign.Flags.ShipOwned := true;
  end;
end;

procedure BuyScroll(Price: word);

const
  Caption = 'Вы можете eше взять # волшебств:';

var
  I, Count: byte;

begin
  Count := 0;
  for I := 0 to 13 do Inc(Count, Game.Campaign.Scrolls[I]);

  if Count < Game.Campaign.ScrollCapacity then
  begin
    if not PaymentFailed(Price) then
    begin
    Inc(Game.Campaign.Scrolls[Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Scroll]);
    Inc(Count);
    Game.World.GenerationCount := Game.Campaign.ScrollCapacity - Count;
    Str(Game.World.GenerationCount, Game.Runtime.TextBuffer);
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 13, 272, Caption);
    DrawText(false, 46, 272, Game.Runtime.TextBuffer);
    Game.Runtime.LastScan := ReadScanCode;
    end;
  end
  else ShowNotice(3);
end;

procedure GoodsMarket;
var
  Product: byte;
  BuyMode: boolean;
  Spread: word;

procedure SellQuantity(var Cargo: word; var Stock: byte);
var
  Quantity: longint;

begin
  if not ReadQuantity(Quantity) then Game.Runtime.LastScan := 48
  else if Cargo >= Quantity then
  begin
    Game.Campaign.Gold := Game.Runtime.GoodsSellPrices[Product] * Quantity + Game.Campaign.Gold;
    Cargo := Cargo - Quantity;
    Stock := Stock + Quantity;
  end;
end;

procedure GoodsTransaction;

const
  GoldBlank = '       ';
  QuantityBlank = '            ';

var
  Capacity, Price: word;

begin
  if BuyMode then
  begin
    Capacity := Game.Runtime.GoodsStock[Product];
    Price := Game.Runtime.GoodsBuyPrices[Product];
    BuyByteQuantity(Capacity, Price, Game.Campaign.Cargo[Product], Game.Runtime.GoodsStock[Product]);

    if Game.Runtime.LastScan = 27 then Exit;
    if (Game.Campaign.Cargo[Product] > 0) and (Game.Campaign.CargoMaxPrices[Product] < Price) then
      Game.Campaign.CargoMaxPrices[Product] := Price;
    Str(Game.Runtime.GoodsStock[Product]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
  end
  else
  begin
    SellQuantity(Game.Campaign.Cargo[Product], Game.Runtime.GoodsStock[Product]);

    if Game.Campaign.Cargo[Product] = 0 then Game.Campaign.CargoMaxPrices[Product] := 0;
    Str(Game.Campaign.Cargo[Product]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
  end;

  DrawText(false, 52, 240, GoldBlank);
  Str(Game.Campaign.Gold, Game.Runtime.TextBuffer);
  DrawText(false, 52, 240, Game.Runtime.TextBuffer);
  DrawText(false, 45, 304, QuantityBlank);
  HeaderPrompt(3);
end;

procedure GoodsModeCaption(BuySelected, SellSelected: boolean);

const
  BuyCaption = #138#227#175#168#226#236'('#167#160'#1)';
  SellCaption = #143'p'#174#164#160#226#236'('#167#160'#1)';
begin
  DrawText(BuySelected, 20, 240, BuyCaption);
  DrawText(SellSelected, 34, 240, SellCaption);
end;

procedure ToggleGoodsMode;
var
  I: byte;

begin
  BuyMode := not BuyMode;
  if BuyMode then
  begin
    GoodsModeCaption(true, false);

    for I := 1 to 7 do
    begin
      Str(Game.Runtime.GoodsStock[I]: 3, Game.Runtime.TextBuffer);
      DrawText(false, 16,(I - 1) * 8 + 256, Game.Runtime.TextBuffer);
    end;
  end
  else
  begin
    GoodsModeCaption(false, true);

    for I := 1 to 7 do
    begin
      Str(Game.Campaign.Cargo[I]: 3, Game.Runtime.TextBuffer);
      DrawText(false, 16,(I - 1) * 8 + 256, Game.Runtime.TextBuffer);
    end;
  end;
end;

begin
  BuyMode := true;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(3);
  GoodsModeCaption(true, false);
  Str(Game.Campaign.Gold, Game.Runtime.TextBuffer);
  Game.Runtime.TextBuffer := '$' + Game.Runtime.TextBuffer;
  DrawText(false, 51, 240, Game.Runtime.TextBuffer);

  for Product := 1 to 7 do DrawText(false, 5,(Product - 1) * 8 + 256, GoodsNames[Product]);
  if (Game.Runtime.GoodsMarketTown <> TownState.Slot) or (Game.Runtime.GoodsMarketIsland <> Game.Campaign.Island) or
     (Game.Runtime.GoodsMarketAge > 40) then
    for Product := 1 to 7 do
    begin
      Spread := Random(100);

      if Spread < 20 then Spread := 0;
      Game.Runtime.GoodsStock[Product] := Lo(Spread);
      Spread := Random(GoodsTownVariations[Game.Campaign.Island, TownState.Slot]);
      Game.Runtime.GoodsSellPrices[Product] := GoodsBasePrices[Product] - Spread;
      Spread := Random(GoodsTownVariations[Game.Campaign.Island, TownState.Slot]);
      Game.Runtime.GoodsBuyPrices[Product] := Game.Runtime.GoodsSellPrices[Product] + Spread;
    end;

  for Product := 1 to 7 do
  begin
    Str(Product, Game.Runtime.TextBuffer);
    Game.Runtime.TextBuffer := Game.Runtime.TextBuffer + ')';
    DrawText(false, 2,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
    Str(Game.Runtime.GoodsStock[Product]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
    Str(Game.Runtime.GoodsBuyPrices[Product]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 25,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
    Str(Game.Runtime.GoodsSellPrices[Product]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 39,(Product - 1) * 8 + 256, Game.Runtime.TextBuffer);
  end;

  repeat
    Game.Runtime.LastScan := Ord(ReadKey);
    Val(Chr(Game.Runtime.LastScan), Product, Game.World.GenerationCount);

    case Game.Runtime.LastScan of
      49..55: GoodsTransaction;
      9: ToggleGoodsMode;
    end;
  until Game.Runtime.LastScan = 27;
  Game.Runtime.LastScan := 48;
  HeaderPrompt(2);
  Game.Runtime.GoodsMarketAge := 0;
  Game.Runtime.GoodsMarketTown := TownState.Slot;
  Game.Runtime.GoodsMarketIsland := Game.Campaign.Island;
end;

procedure OfferContract;
label
  Found;

const
  Caption = 'Вы согласны заключить контpакт? (Y-да/N-нет)';

var
  I, Count: byte;

begin
  Count := 0;
  for I := 1 to 5 do
    if Game.Campaign.Contracts[Game.Campaign.Island, I].Island < 100 then
      if not Game.Campaign.Castles[Game.Campaign.Contracts[Game.Campaign.Island, I].Island,
        Game.Campaign.Contracts[Game.Campaign.Island, I].Slot].Owned then Inc(Count);
  if Count = 0 then
  begin
    ShowNotice(14);
    Game.Campaign.QuestFlags[Game.Campaign.Island] := 100;
  end
  else
  begin
    repeat
      if Game.Runtime.CurrentContractOffer > 4 then Game.Runtime.CurrentContractOffer := 1
      else Inc(Game.Runtime.CurrentContractOffer);

      if Game.Campaign.Contracts[Game.Campaign.Island, Game.Runtime.CurrentContractOffer].Island < 100 then
        if not Game.Campaign.Castles[Game.Campaign.Contracts[Game.Campaign.Island,
    Game.Runtime.CurrentContractOffer].Island,
          Game.Campaign.Contracts[Game.Campaign.Island, Game.Runtime.CurrentContractOffer].Slot].Owned then begin
          ContractReport(Game.Campaign.Contracts[Game.Campaign.Island, Game.Runtime.CurrentContractOffer].Island,
    Game.Campaign.Contracts[Game.Campaign.Island,
            Game.Runtime.CurrentContractOffer].Slot);
          goto Found;
        end;
    until false;
Found:
    DrawText(false, 10, 304, Caption);
    Game.Runtime.LastScan := ReadScanCode;

    if Game.Runtime.LastScan = 21 then
    begin
      Game.Campaign.ContractIsland := Game.Campaign.Island;
      Game.Campaign.ContractSlot := Game.Runtime.CurrentContractOffer;
      Game.Runtime.PicturePage := 0;
      DrawPictureTile(1822, 17);
      Game.Runtime.PicturePage := 32768;
      ShowNotice(19);
    end;
  end;
end;

begin
  Game.Runtime.PicturePage := 32768;
  if Game.Runtime.TownPictureLoaded then TownState.LoadedTownArtwork := false
  else
  begin
    Game.Runtime.PictureFileName := TownPictureName;
    LoadScreenPicture;
    Game.Runtime.TownPictureLoaded := true;
    TownState.LoadedTownArtwork := true;
  end;

  SetVideoPage(1);
  TownState.Slot := 0;
  TownState.JournalIndex := -1;

  repeat
    Inc(TownState.Slot)
  until (Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].X = Game.World.GenerationX) and
    (Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Y = Game.World.GenerationY);
  repeat
    Inc(TownState.JournalIndex)
  until ((Game.Campaign.VisitedTowns[TownState.JournalIndex].Island = Game.Campaign.Island)
    and (Game.Campaign.VisitedTowns[TownState.JournalIndex].Slot = TownState.Slot)) or (TownState.JournalIndex = 25);

  if TownState.JournalIndex = 25 then
  begin
    TownState.JournalIndex := 0;

    while Game.Campaign.VisitedTowns[TownState.JournalIndex].Island > 0 do Inc(TownState.JournalIndex);
    Game.Campaign.VisitedTowns[TownState.JournalIndex].Island := Game.Campaign.Island;
    Game.Campaign.VisitedTowns[TownState.JournalIndex].Slot := TownState.Slot;
  end;

  repeat
    if (Game.Campaign.Island > 1) and (TownState.Slot = 1) then HeaderPrompt(9)
    else HeaderPrompt(2);
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 2, 240, TownCaption);
    DrawText(false, 9, 240, TownNames[Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Name]);
    DrawText(false, 42, 240, GoldCaption);
    Str(Game.Campaign.Gold, Game.Runtime.TextBuffer);
    DrawText(false, 51, 240, Game.Runtime.TextBuffer);
    DrawText(false, 2, 256, ContractMenuItem);
    DrawText(false, 2, 264, ShipMenuCaptions[Game.Campaign.Flags.ShipOwned]);
    DrawText(false, 2, 272, CastleMenuItem);
    DrawText(false, 2, 280, ScrollMenuPrefix);
    Str(ScrollPrices[Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Scroll], TownState.Caption);
    TownState.Caption := ScrollNames[Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Scroll] +
    PricePrefix + TownState.Caption +
      PriceSuffix;
    DrawText(false, 5, 280, TownState.Caption);
    DrawText(false, 2, 288, SiegeEngineMenuItem);
    DrawText(false, 2, 296, WorkersMenuItem);
    DrawText(false, 2, 304, GoodsMenuItem);
    Game.Runtime.LastScan := Ord(ReadKey);

    case Game.Runtime.LastScan of
      49: OfferContract;
      50: BuyShip;
      51: begin
        TownState.Caption := CastleCaption + CastleNames[Game.Campaign.Castles[Game.Campaign.Island,
    TownState.Slot].Name];

        if ArmyReport(TReportSpecies(Game.Campaign.Castles[Game.Campaign.Island, TownState.Slot].Species),
          TReportCounts(Game.Campaign.Castles[Game.Campaign.Island, TownState.Slot].Counts), TownState.Caption) then
        begin
        end;

        Game.Runtime.LastScan := ReadScanCode;
      end;

      52: BuyScroll(ScrollPrices[Game.Campaign.Towns[Game.Campaign.Island, TownState.Slot].Scroll]);
      53: if not PaymentFailed(3000) then
      begin
        Game.Runtime.PicturePage := 0;
        DrawPictureTile(6622, 16);
        Game.Runtime.PicturePage := 32768;
        Game.Campaign.Flags.SiegeEngineOwned := true;
      end;

      54: WorkerMarket;
      55: GoodsMarket;
      56: if (Game.Campaign.Island > 1) and (TownState.Slot = 1) and not
    Game.Campaign.Relics[Game.Campaign.Island].Owned then
      begin
        ShowNotice(18);
        Game.Campaign.Relics[Game.Campaign.Island].Owned := true;
      end;
    end;
  until Game.Runtime.LastScan = 27;
  SetVideoPage(0);

  if TownState.LoadedTownArtwork then
  begin
    LoadResourceFile(Game.Runtime.PictureBanks[4], Game.Runtime.IslandPictureFileName);
    LoadResourceFile(Game.Runtime.PictureBanks[5], Game.Runtime.ChartPictureFileName);
  end;

  Game.Runtime.PicturePage := 0;
  Game.Runtime.LastScan := 48;
  HeaderPrompt(0);
  RefreshGold;
end;

end.
