procedure PlaceShip(X, Y: byte);
begin
  Game.ShipIsland := Game.Island;
  Game.Ship.X := X;
  Game.Ship.Y := Y;
  Game.ShipBackground := Game.Map[Game.Island, X, Y];
  Game.Map[Game.Island, X, Y] := 14;
  ComposeTile(Game.ShipBackground);
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
    Str(Game.Gold, Game.TextBuffer);
    DrawText(false, 51, 240, Game.TextBuffer);
    DrawText(false, 2, 256, CarpentersMenuItem);
    Str(Game.Towns[Game.Island, TownState.Slot].Workers[1], Game.TextBuffer);
    DrawText(false, 22, 256, Game.TextBuffer);
    DrawText(false, 2, 264, WoodcuttersMenuItem);
    Str(Game.Towns[Game.Island, TownState.Slot].Workers[2], Game.TextBuffer);
    DrawText(false, 22, 264, Game.TextBuffer);
    DrawText(false, 2, 272, DiggersMenuItem);
    Str(Game.Towns[Game.Island, TownState.Slot].Workers[4], Game.TextBuffer);
    DrawText(false, 22, 272, Game.TextBuffer);
    DrawText(false, 2, 280, StonecuttersMenuItem);
    Str(Game.Towns[Game.Island, TownState.Slot].Workers[3], Game.TextBuffer);
    DrawText(false, 22, 280, Game.TextBuffer);
    Game.LastScan := ReadScanCode;

    case Game.LastScan of
      2: BuyByteQuantity(Game.Towns[Game.Island, TownState.Slot].Workers[1], 500, Game.Carpenters,
        Game.Towns[Game.Island, TownState.Slot].Workers[1]);
      3: BuyByteQuantity(Game.Towns[Game.Island, TownState.Slot].Workers[2], 500, Game.Woodcutters,
        Game.Towns[Game.Island, TownState.Slot].Workers[2]);
      4: BuyByteQuantity(Game.Towns[Game.Island, TownState.Slot].Workers[4], 800, Game.Diggers,
        Game.Towns[Game.Island, TownState.Slot].Workers[4]);
      5: BuyByteQuantity(Game.Towns[Game.Island, TownState.Slot].Workers[3], 800, Game.Stonecutters,
        Game.Towns[Game.Island, TownState.Slot].Workers[3]);
    end;
  until Game.LastScan = 1;
  HeaderPrompt(2);
  Game.LastScan := 48;
end;

procedure BuyShip;
label
  Found;

var
  DX, DY: shortint;

begin
  if Game.ShipOwned then
    if Game.ShipAbandonBlocked then Exit
    else
    begin
      AbandonShip;
      Exit
    end;

  begin
    if PaymentFailed(ShipPurchasePrice) then Exit;
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if (Game.Map[Game.Island, Game.Towns[Game.Island, TownState.Slot].X + DX, Game.Towns[Game.Island,
          TownState.Slot].Y + DY] >= 48) and
          (Game.Map[Game.Island, Game.Towns[Game.Island, TownState.Slot].X + DX,
          Game.Towns[Game.Island, TownState.Slot].Y + DY] < 64) then goto Found;
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if Game.Map[Game.Island, Game.Towns[Game.Island, TownState.Slot].X + DX,
          Game.Towns[Game.Island, TownState.Slot].Y + DY] = 4 then goto Found;
Found:
    PlaceShip(Game.Towns[Game.Island, TownState.Slot].X + DX, Game.Towns[Game.Island, TownState.Slot].Y + DY);
    Game.ShipOwned := true;
  end;
end;

procedure BuyScroll(Price: word);

const
  Caption = 'Вы можете eше взять # волшебств:';

var
  I, Count: byte;

begin
  Count := 0;
  for I := 0 to 13 do Inc(Count, Game.Scrolls[I]);

  if Count < Game.ScrollCapacity then
  begin
    if not PaymentFailed(Price) then
    begin
    Inc(Game.Scrolls[Game.Towns[Game.Island, TownState.Slot].Scroll]);
    Inc(Count);
    Game.GenerationCount := Game.ScrollCapacity - Count;
    Str(Game.GenerationCount, Game.TextBuffer);
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 13, 272, Caption);
    DrawText(false, 46, 272, Game.TextBuffer);
    Game.LastScan := ReadScanCode;
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
  if not ReadQuantity(Quantity) then Game.LastScan := 48
  else if Cargo >= Quantity then
  begin
    Game.Gold := Game.GoodsSellPrices[Product] * Quantity + Game.Gold;
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
    Capacity := Game.GoodsStock[Product];
    Price := Game.GoodsBuyPrices[Product];
    BuyByteQuantity(Capacity, Price, Game.Cargo[Product], Game.GoodsStock[Product]);

    if Game.LastScan = 27 then Exit;
    if (Game.Cargo[Product] > 0) and (Game.CargoMaxPrices[Product] < Price) then
      Game.CargoMaxPrices[Product] := Price;
    Str(Game.GoodsStock[Product]: 3, Game.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.TextBuffer);
  end
  else
  begin
    SellQuantity(Game.Cargo[Product], Game.GoodsStock[Product]);

    if Game.Cargo[Product] = 0 then Game.CargoMaxPrices[Product] := 0;
    Str(Game.Cargo[Product]: 3, Game.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.TextBuffer);
  end;

  DrawText(false, 52, 240, GoldBlank);
  Str(Game.Gold, Game.TextBuffer);
  DrawText(false, 52, 240, Game.TextBuffer);
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
      Str(Game.GoodsStock[I]: 3, Game.TextBuffer);
      DrawText(false, 16,(I - 1) * 8 + 256, Game.TextBuffer);
    end;
  end
  else
  begin
    GoodsModeCaption(false, true);

    for I := 1 to 7 do
    begin
      Str(Game.Cargo[I]: 3, Game.TextBuffer);
      DrawText(false, 16,(I - 1) * 8 + 256, Game.TextBuffer);
    end;
  end;
end;

begin
  BuyMode := true;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(3);
  GoodsModeCaption(true, false);
  Str(Game.Gold, Game.TextBuffer);
  Game.TextBuffer := '$' + Game.TextBuffer;
  DrawText(false, 51, 240, Game.TextBuffer);

  for Product := 1 to 7 do DrawText(false, 5,(Product - 1) * 8 + 256, GoodsNames[Product]);
  if (Game.GoodsMarketTown <> TownState.Slot) or (Game.GoodsMarketIsland <> Game.Island) or
     (Game.GoodsMarketAge > 40) then
    for Product := 1 to 7 do
    begin
      Spread := Random(100);

      if Spread < 20 then Spread := 0;
      Game.GoodsStock[Product] := Lo(Spread);
      Spread := Random(GoodsTownVariations[Game.Island, TownState.Slot]);
      Game.GoodsSellPrices[Product] := GoodsBasePrices[Product] - Spread;
      Spread := Random(GoodsTownVariations[Game.Island, TownState.Slot]);
      Game.GoodsBuyPrices[Product] := Game.GoodsSellPrices[Product] + Spread;
    end;

  for Product := 1 to 7 do
  begin
    Str(Product, Game.TextBuffer);
    Game.TextBuffer := Game.TextBuffer + ')';
    DrawText(false, 2,(Product - 1) * 8 + 256, Game.TextBuffer);
    Str(Game.GoodsStock[Product]: 3, Game.TextBuffer);
    DrawText(false, 16,(Product - 1) * 8 + 256, Game.TextBuffer);
    Str(Game.GoodsBuyPrices[Product]: 3, Game.TextBuffer);
    DrawText(false, 25,(Product - 1) * 8 + 256, Game.TextBuffer);
    Str(Game.GoodsSellPrices[Product]: 3, Game.TextBuffer);
    DrawText(false, 39,(Product - 1) * 8 + 256, Game.TextBuffer);
  end;

  repeat
    Game.LastScan := Ord(ReadKey);
    Val(Chr(Game.LastScan), Product, Game.GenerationCount);

    case Game.LastScan of
      49..55: GoodsTransaction;
      9: ToggleGoodsMode;
    end;
  until Game.LastScan = 27;
  Game.LastScan := 48;
  HeaderPrompt(2);
  Game.GoodsMarketAge := 0;
  Game.GoodsMarketTown := TownState.Slot;
  Game.GoodsMarketIsland := Game.Island;
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
    if Game.Contracts[Game.Island, I].Island < 100 then
      if not Game.Castles[Game.Contracts[Game.Island, I].Island,
        Game.Contracts[Game.Island, I].Slot].Owned then Inc(Count);
  if Count = 0 then
  begin
    ShowNotice(14);
    Game.QuestFlags[Game.Island] := 100;
  end
  else
  begin
    repeat
      if Game.CurrentContractOffer > 4 then Game.CurrentContractOffer := 1
      else Inc(Game.CurrentContractOffer);

      if Game.Contracts[Game.Island, Game.CurrentContractOffer].Island < 100 then
        if not Game.Castles[Game.Contracts[Game.Island, Game.CurrentContractOffer].Island,
          Game.Contracts[Game.Island, Game.CurrentContractOffer].Slot].Owned then begin
          ContractReport(Game.Contracts[Game.Island, Game.CurrentContractOffer].Island, Game.Contracts[Game.Island,
            Game.CurrentContractOffer].Slot);
          goto Found;
        end;
    until false;
Found:
    DrawText(false, 10, 304, Caption);
    Game.LastScan := ReadScanCode;

    if Game.LastScan = 21 then
    begin
      Game.ContractIsland := Game.Island;
      Game.ContractSlot := Game.CurrentContractOffer;
      Game.PicturePage := 0;
      DrawPictureTile(1822, 17);
      Game.PicturePage := 32768;
      ShowNotice(19);
    end;
  end;
end;

begin
  Game.PicturePage := 32768;
  if Game.TownPictureLoaded then TownState.LoadedTownArtwork := false
  else
  begin
    Game.PictureFileName := TownPictureName;
    LoadScreenPicture;
    Game.TownPictureLoaded := true;
    TownState.LoadedTownArtwork := true;
  end;

  SetVideoPage(1);
  TownState.Slot := 0;
  TownState.JournalIndex := -1;

  repeat
    Inc(TownState.Slot)
  until (Game.Towns[Game.Island, TownState.Slot].X = Game.GenerationX) and
    (Game.Towns[Game.Island, TownState.Slot].Y = Game.GenerationY);
  repeat
    Inc(TownState.JournalIndex)
  until ((Game.VisitedTowns[TownState.JournalIndex].Island = Game.Island)
    and (Game.VisitedTowns[TownState.JournalIndex].Slot = TownState.Slot)) or (TownState.JournalIndex = 25);

  if TownState.JournalIndex = 25 then
  begin
    TownState.JournalIndex := 0;

    while Game.VisitedTowns[TownState.JournalIndex].Island > 0 do Inc(TownState.JournalIndex);
    Game.VisitedTowns[TownState.JournalIndex].Island := Game.Island;
    Game.VisitedTowns[TownState.JournalIndex].Slot := TownState.Slot;
  end;

  repeat
    if (Game.Island > 1) and (TownState.Slot = 1) then HeaderPrompt(9)
    else HeaderPrompt(2);
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 2, 240, TownCaption);
    DrawText(false, 9, 240, TownNames[Game.Towns[Game.Island, TownState.Slot].Name]);
    DrawText(false, 42, 240, GoldCaption);
    Str(Game.Gold, Game.TextBuffer);
    DrawText(false, 51, 240, Game.TextBuffer);
    DrawText(false, 2, 256, ContractMenuItem);
    DrawText(false, 2, 264, ShipMenuCaptions[Game.ShipOwned]);
    DrawText(false, 2, 272, CastleMenuItem);
    DrawText(false, 2, 280, ScrollMenuPrefix);
    Str(ScrollPrices[Game.Towns[Game.Island, TownState.Slot].Scroll], TownState.Caption);
    TownState.Caption := ScrollNames[Game.Towns[Game.Island, TownState.Slot].Scroll] + PricePrefix + TownState.Caption +
      PriceSuffix;
    DrawText(false, 5, 280, TownState.Caption);
    DrawText(false, 2, 288, SiegeEngineMenuItem);
    DrawText(false, 2, 296, WorkersMenuItem);
    DrawText(false, 2, 304, GoodsMenuItem);
    Game.LastScan := Ord(ReadKey);

    case Game.LastScan of
      49: OfferContract;
      50: BuyShip;
      51: begin
        TownState.Caption := CastleCaption + CastleNames[Game.Castles[Game.Island, TownState.Slot].Name];

        if ArmyReport(TReportSpecies(Game.Castles[Game.Island, TownState.Slot].Species),
          TReportCounts(Game.Castles[Game.Island, TownState.Slot].Counts), TownState.Caption) then
        begin
        end;

        Game.LastScan := ReadScanCode;
      end;

      52: BuyScroll(ScrollPrices[Game.Towns[Game.Island, TownState.Slot].Scroll]);
      53: if not PaymentFailed(3000) then
      begin
        Game.PicturePage := 0;
        DrawPictureTile(6622, 16);
        Game.PicturePage := 32768;
        Game.SiegeEngineOwned := true;
      end;

      54: WorkerMarket;
      55: GoodsMarket;
      56: if (Game.Island > 1) and (TownState.Slot = 1) and not Game.Relics[Game.Island].Owned then
      begin
        ShowNotice(18);
        Game.Relics[Game.Island].Owned := true;
      end;
    end;
  until Game.LastScan = 27;
  SetVideoPage(0);

  if TownState.LoadedTownArtwork then
  begin
    LoadResourceFile(Game.PictureBanks[4], Game.IslandPictureFileName);
    LoadResourceFile(Game.PictureBanks[5], Game.ChartPictureFileName);
  end;

  Game.PicturePage := 0;
  Game.LastScan := 48;
  HeaderPrompt(0);
  RefreshGold;
end;
