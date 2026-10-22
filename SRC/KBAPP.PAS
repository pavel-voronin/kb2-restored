unit KBApp;
{$G+,R-,S-,I+,A+}

interface

procedure RunGame;

implementation

uses KBMotion, KBArmy, KBCastle, KBDwell, KBHelp, KBHero, KBHud, KBLoad, KBMagic, KBMap, KBSaveUI, KBScroll,
    KBTown, KBVisit, KBWizard, Dos, Crt, KBState, KBGfx, KBInput, KBFiles, KBUI, KBView, KBSave, KBStart, KBWorker,
    KBCal, KBAdvent, KBSess, KBEvents;

procedure WaitForCommand;
label
  InputReady;
begin
  Game.Runtime.ActionScratch := Game.Campaign.MagicPower;

  while not KeyPressed do
  begin
    if Game.Campaign.Gold > 999999 then
    begin
      Game.Runtime.WealthPicture := Random(39) div 10 + 128;
      DrawPictureTile(16222, Game.Runtime.WealthPicture);
    end;

    if Game.Runtime.IdlePowerPhase > 0 then
    begin
      Game.Campaign.MagicPower := Random(shortint(Game.Runtime.ActionScratch) * 2 + 1) shr 1;
      RefreshMagic;
      Game.Runtime.IdlePowerPhase := 0;
    end
    else Inc(Game.Runtime.IdlePowerPhase);

    for Game.Runtime.IdleCounter := 1 to 200 do
      if KeyPressed then goto InputReady
      else Delay(2);
  end;

InputReady:
  Game.Campaign.MagicPower := Game.Runtime.ActionScratch;
  RevealNearbyTiles;
  MoveRoamer(Game.Campaign.Island, 12, Game.World.WizardPosition);
  Game.World.GenerationX := Game.Campaign.Hero.X;
  Game.World.GenerationY := Game.Campaign.Hero.Y;
  Game.Runtime.LastScan := ReadScanCode;

end;

procedure DispatchCommand;
begin
  case Game.Runtime.LastScan of
    68: begin
    end;

    71: if (Game.World.GenerationX > 2) and (Game.World.GenerationY > 2) then
    begin
      Dec(Game.World.GenerationX);
      Dec(Game.World.GenerationY)
    end;

    72: if Game.World.GenerationY > 2 then Dec(Game.World.GenerationY);
    73: if (Game.World.GenerationX < 63) and (Game.World.GenerationY > 2) then
    begin
      Inc(Game.World.GenerationX);
      Dec(Game.World.GenerationY)
    end;

    75: if Game.World.GenerationX > 2 then Dec(Game.World.GenerationX);
    77: if Game.World.GenerationX < 63 then Inc(Game.World.GenerationX);
    79: if (Game.World.GenerationX > 2) and (Game.World.GenerationY < 63) then
    begin
      Dec(Game.World.GenerationX);
      Inc(Game.World.GenerationY)
    end;

    80: if Game.World.GenerationY < 63 then Inc(Game.World.GenerationY);
    81: if (Game.World.GenerationX < 63) and (Game.World.GenerationY < 63) then
    begin
      Inc(Game.World.GenerationX);
      Inc(Game.World.GenerationY)
    end;

    17: WorkersMenu(Game.Campaign.Island);
    18: begin
      Game.Campaign.ExtraDays := 0;
      Game.Campaign.Days := 1
    end;

    19: RitualSpellReport;
    20: CastTornado;
    22: if not Game.Runtime.ShipAbandonBlocked then AdventureMagic;
    23: CurrentContract;
    24: AdventureHelp;
    25: ShowNotice(20);
    30: ArmyOverview;
    31: if not Game.Runtime.ShipAbandonBlocked then
    begin
      PrepareSave;
      WriteCampaign;
      ShowNotice(23)
    end;

    32: DismissArmy;
    33: Game.Runtime.SoundDisabled := not Game.Runtime.SoundDisabled;
    34: Credits;
    46: SearchRitualSpell;
    47: HeroStatus;
    48: CargoReport;
    49: if Game.Runtime.ShipAbandonBlocked then SeaVoyage;
    50: MapVisit(Game.Campaign.Island);
  else Game.Runtime.LastScan := 71;
  end;

end;

procedure UpdateHeroFacing;
begin
  if (Game.Runtime.LastScan in [71, 75, 79]) and not Game.Campaign.Flags.Heading then
  begin
    if Game.Runtime.ShipAbandonBlocked then MirrorTileArt(15)
    else MirrorTileArt(6);
    Game.Campaign.Flags.Heading := true;
  end
  else if (Game.Runtime.LastScan in [73, 77, 81]) and Game.Campaign.Flags.Heading then
  begin
    if Game.Runtime.ShipAbandonBlocked then MirrorTileArt(15)
    else MirrorTileArt(6);
    Game.Campaign.Flags.Heading := false;
  end;

end;

procedure ResolveMovement;
begin
  if Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX, Game.World.GenerationY] >= 64 then
  begin
    Sound(200);
    Delay(30);
    NoSound;
    Game.World.GenerationX := Game.Campaign.Hero.X;
    Game.World.GenerationY := Game.Campaign.Hero.Y;
  end
  else
  begin
    Sound(600);
    Delay(2);
    NoSound;
    Inc(Game.Runtime.GoodsMarketAge);
  end;

  if Game.Runtime.RegrowthCountdown > 0 then RegrowMountain;
  if Game.Runtime.LastScan > 70 then
  begin
    Game.Runtime.ActionScratch := Game.Campaign.EnemyGrace;
    AdvanceNearbyRoamers;

    if Game.Runtime.WorldMapPending <> 0 then MoveRoamer(Game.Campaign.Island, 28, Game.World.MagePosition);
    if (shortint(Game.Runtime.ActionScratch) > 0) and (Game.Campaign.EnemyGrace = 0) then
      CopyRecord(0, 5, 2880, Game.Runtime.PictureBanks[13], Game.Runtime.PictureBanks[0]);
    case Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX, Game.World.GenerationY] of
      32..47: SandLanding;
      48..63: if Game.Runtime.ShipAbandonBlocked then
      begin
        Game.Campaign.Hero.X := Game.World.GenerationX;
        Game.Campaign.Hero.Y := Game.World.GenerationY
      end;

      2: CastleVisit;
      18: CastleVisit;
      4: begin
        Game.Campaign.Hero.X := Game.World.GenerationX;
        Game.Campaign.Hero.Y := Game.World.GenerationY
      end;

      7: TownVisit;
      8: DwellingVisit;
      5: WanderingArmyVisit;
      9: PaperScrollVisit;
      10: TreasureVisit;
      11: begin
        UndergroundVisit;
        Game.Campaign.Hero.X := Game.World.GenerationX;
        Game.Campaign.Hero.Y := Game.World.GenerationY
      end;

      12: WizardVisit;
      28: BlackMage;
      22: TalkingStoneVisit;
      23: RitualGuardianVisit;
      14: BoardShip;
      0: EncounterLanding;
    end;
  end;

end;

procedure AdvanceAdventureTime;
begin
  if Game.Campaign.ExtraDays > 0 then
  begin
    Dec(Game.Campaign.ExtraDays);
    DrawTime
  end
  else
  begin
    Dec(Game.Campaign.Days);

    if Game.Campaign.Days = 0 then EndWeek;
  end;

end;

function ConfirmExit: boolean;
begin
  ConfirmExit := false;
  ShowNotice(13);
  if Game.Runtime.LastScan <> 21 then Exit;

  if not Game.Runtime.ShipAbandonBlocked then
  begin
    ShowNotice(15);

    if Game.Runtime.LastScan = 21 then SaveNamedGame;
  end;

  ConfirmExit := true;
end;

procedure RunGame;
var
  Finished: boolean;
begin
  Game.Runtime.CachedCreatureId := 100;
  SetGraphicsMode(1);
  InitializeRuntime;
  LoadTitle;
  StartupMenu;
  LoadGameArtwork;
  RefreshDwellings;
  PrepareLoadedCampaign;
  RestoreControls;
  Finished := false;
  repeat
    DrawAdventureField;
    WaitForCommand;
    DispatchCommand;
    UpdateHeroFacing;
    ResolveMovement;
    AdvanceAdventureTime;
    if Game.Runtime.LastScan = 68 then Finished := ConfirmExit;
  until Finished;
  CleanupGame;
end;

end.
