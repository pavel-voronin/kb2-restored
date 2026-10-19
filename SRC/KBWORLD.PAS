unit KBWorld;
{$G+,R-,S-,I+,A+}

interface

uses KBState;

procedure ForgetDiscovery;

procedure PlaceRoamingObject(Island, Code: byte; var P: TPosition);

procedure EnterIsland(Island: byte);

procedure PrepareCampaign(Level: byte);

procedure GenerateWorld(Level: byte);

procedure PlaceInitialHero(Level: byte);

implementation

uses KBTables;

procedure ForgetDiscovery;
begin
  FillChar(Game.Discovery, SizeOf(Game.Discovery), 0);
  FillChar(Game.VisitedCastles, SizeOf(Game.VisitedCastles), 0);
  FillChar(Game.VisitedTowns, SizeOf(Game.VisitedTowns), 0);
end;

procedure PlaceRoamingObject(Island, Code: byte; var P: TPosition);
begin
  repeat
    P.X := Random(65);
    P.Y := Random(65);
  until Game.Map[Island, P.X, P.Y] = 0;
  Game.Map[Island, P.X, P.Y] := Code;
end;

procedure EnterIsland(Island: byte);
begin
  Game.Map[Game.Island, Game.WizardPosition.X, Game.WizardPosition.Y] := 0;
  Game.Map[Game.Island, Game.MagePosition.X, Game.MagePosition.Y] := 0;

  if Island = 0 then Island := Random(5) + 1;
  if Island > 5 then Island := 5;
  PlaceRoamingObject(Island, 12, Game.WizardPosition);
  PlaceRoamingObject(Island, 28, Game.MagePosition);
  Game.Island := Island;
end;

procedure FillIsland(Island, Terrain: byte);
begin
  asm
    mov ax, ds
    mov es, ax
    mov al, Island
    dec al
    xor ah, ah
    mov dx, $1104
    mov cx, dx
    mul dx
    lea di, Game.Map
    add di, ax
    mov al, Terrain
    mov ah, al
    shr cx, 1
    rep stosw
  end;
end;

procedure PrepareCampaign(Level: byte);
var
  I: byte;

begin
  FillIsland(1, 0);
  FillIsland(2, 48);
  FillIsland(3, 64);
  FillIsland(4, 80);
  FillIsland(5, 80);
  FillChar(Game.WanderingArmies, SizeOf(Game.WanderingArmies), 100);
  FillChar(Game.Army, SizeOf(Game.Army), 100);
  FillChar(Game.Scrolls, SizeOf(Game.Scrolls), 0);
  FillChar(Game.Discovery, SizeOf(Game.Discovery), 0);
  FillChar(Game.LocalMapOwned, SizeOf(Game.LocalMapOwned), 0);
  FillChar(Game.WizardRelations, SizeOf(Game.WizardRelations), 0);
  FillChar(Game.WizardVisited, SizeOf(Game.WizardVisited), 0);
  FillChar(Game.Cargo, SizeOf(Game.Cargo), 0);
  FillChar(Game.CargoMaxPrices, SizeOf(Game.CargoMaxPrices), 0);
  FillChar(Game.VisitedCastles, SizeOf(Game.VisitedCastles), 0);
  FillChar(Game.VisitedTowns, SizeOf(Game.VisitedTowns), 0);
  FillChar(Game.QuestFlags, SizeOf(Game.QuestFlags), 3);
  FillChar(Game.SpellAvailable, SizeOf(Game.SpellAvailable), 0);
  FillChar(Game.SpellUsed, SizeOf(Game.SpellUsed), 0);
  Game.Mutants[25].Name := 'åìêãÄçíõ1';
  Game.Mutants[26].Name := 'åìêãÄçíõ2';
  Game.Mutants[27].Name := 'åìêãÄçíõ3';
  Game.Mutants[28].Name := 'åìêãÄçíõ4';
  Game.Mutants[29].Name := 'åìêãÄçíõ5';

  for I := 0 to 27 do
  begin
    Game.TownNamePool[I] := I;
    Game.CastleNamePool[I] := I;
  end;

  for I := 0 to 7 do Game.SpellColorPool[I] := I;
  for I := 2 to 5 do Game.Relics[I].Owned := false;
  Game.Relics[2].Artwork := 26;
  Game.Relics[3].Artwork := 25;
  Game.Relics[4].Artwork := 24;
  Game.Relics[5].Artwork := 27;
  Game.HighestVisitedIsland := 1;
  Game.UnlockedIslands := 1;
  Game.ContractIsland := 100;
  Game.HiddenSpellIsland := 100;
  Game.RitualStoneIsland := 100;
  Game.DamageBonus := 0;
  Game.LeadershipBonus := 0;

  case Level of
    0: begin
      Game.Carpenters := 4;
      Game.Woodcutters := 6;
      Game.Diggers := 0;
      Game.Stonecutters := 3;
      Game.Difficulty := 6;
      Game.MagicPower := 1;
      Game.Gold := 20000;
      Game.ScrollCapacity := 4;
    end;

    1: begin
      Game.Carpenters := 4;
      Game.Woodcutters := 4;
      Game.Diggers := 0;
      Game.Stonecutters := 2;
      Game.Difficulty := 5;
      Game.MagicPower := 1;
      Game.Gold := 15000;
      Game.ScrollCapacity := 3;
    end;

    2: begin
      Game.Carpenters := 2;
      Game.Woodcutters := 3;
      Game.Diggers := 0;
      Game.Stonecutters := 0;
      Game.Difficulty := 4;
      Game.MagicPower := 0;
      Game.Gold := 10000;
      Game.ScrollCapacity := 2;
    end;

    3: begin
      Game.Carpenters := 2;
      Game.Woodcutters := 2;
      Game.Diggers := 0;
      Game.Stonecutters := 0;
      Game.Difficulty := 3;
      Game.MagicPower := 0;
      Game.RitualPower := 0;
      Game.Gold := 0;
      Game.ScrollCapacity := 2;
    end;
  end;

  Game.ExtraDays := 0;
  Game.ShipOwned := false;
  Game.SiegeEngineOwned := false;
  Game.ArmyAvailable := false;
  Game.InstructionsShown := false;

  for I := 1 to 4 do
  begin
    Game.GenerationX := Random(20);

    if Game.GenerationX < 10 then Game.PaperChartPresent[I] := false
    else Game.PaperChartPresent[I] := true;
  end;

  Game.PaperChartPresent[5] := false;
  Game.SceneIsland := 1;
  Game.ShipHeading := 1;
  Randomize;

  for I := 0 to 7 do
  begin
    repeat
      Game.GenerationX := Random(79) div 10;
    until Game.SpellColorPool[Game.GenerationX] <> 255;
    Game.SpellColors[I] := Game.GenerationX;
    Game.SpellColorPool[Game.GenerationX] := 255;
  end;

  Game.Island := 1;
  Game.Weeks := InitialWeekLimits[Level];
  Game.Days := 200;
  Game.Income := 500;
  Game.Leadership := 50;
  Game.EnemyGrace := 40;
  Game.MapParts := 0;
  Game.TornadoCharges := 0;
  Game.Heading := true;
end;

procedure SelectRiverStart;
begin
  Game.GenerationChoice := Random(50);
  if Game.GenerationChoice < 12 then
  begin
    Game.GenerationX := 5;
    Game.GenerationY := Random(65);
  end
  else if Game.GenerationChoice < 25 then
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := 65;
  end
  else if Game.GenerationChoice < 37 then
  begin
    Game.GenerationX := 65;
    Game.GenerationY := Random(65);
  end
  else
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := 5;
  end;
end;

procedure CarveRiver(Level: byte);
label
  RetryTarget;

var
  AlternateX: boolean;
  Budget: word;
  TargetX, TargetY, Major, Minor, Error, StepX, StepY, DiagonalX, DiagonalY: integer;
  SavedMinor, DiagonalIncrement, StraightIncrement: integer;
begin
  AlternateX := true;
  Budget := RiverBudgets[Level, Game.GenerationIsland];

  while Budget > 2 do
  begin
  RetryTarget:
    TargetX := Random(65);
    TargetY := Random(65);

    if (Abs(TargetX - Game.GenerationX) > 15) or (Abs(TargetY - Game.GenerationY) > 15) then goto RetryTarget;
    Minor := TargetY - Game.GenerationY;
    if Minor < 0 then
    begin
      StepY := -1;
      Minor := -Minor;
    end
    else StepY := 1;
    DiagonalY := StepY;
    Major := TargetX - Game.GenerationX;

    if Major < 0 then
    begin
      StepX := -1;
      Major := -Major;
    end
    else StepX := 1;
    DiagonalX := StepX;

    if Major < Minor then
    begin
      StepX := 0;
      Error := Major;
      Major := Minor;
      Minor := Error;
    end
    else StepY := 0;
    SavedMinor := Minor;
    DiagonalIncrement := Minor * 2;
    StraightIncrement := DiagonalIncrement;
    DiagonalIncrement := DiagonalIncrement - Major;
    Error := DiagonalIncrement;
    DiagonalIncrement := DiagonalIncrement - Major;
    Inc(Major);

    while (Budget > 2) and (Major > 0) do
    begin
      if Game.GenerationX < 5 then Game.GenerationX := 5;

      if Game.GenerationY < 5 then Game.GenerationY := 5;
      if Game.GenerationX > 64 then Game.GenerationX := 64;
      if Game.GenerationY > 64 then Game.GenerationY := 64;
      Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 48;
      Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY] := 48;
      Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY + 1] := 48;

      if Error < 0 then
      begin
        Game.GenerationX := Game.GenerationX + StepX;
        Game.GenerationY := Game.GenerationY + StepY;
        Error := Error + StraightIncrement;
      end
      else
      begin
        if AlternateX then Game.GenerationX := Game.GenerationX + DiagonalX
        else
        begin
          Game.GenerationY := Game.GenerationY + DiagonalY;
          Error := Error + DiagonalIncrement;
        end;

        AlternateX := not AlternateX;
      end;

      Dec(Budget, 3);
      Dec(Major);
    end;

    Game.GenerationX := TargetX;
    Game.GenerationY := TargetY;
  end;
end;

procedure ScatterGrass(Level: byte);
var
  Count: word;

begin
  Count := GrassAttempts[Level, Game.GenerationIsland];
  while Count > 0 do
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 0;
    Dec(Count);
  end;
end;

procedure ScatterForest(Level: byte);
var
  Count: word;

begin
  Count := ForestAttempts[Level, Game.GenerationIsland];
  while Count > 0 do
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 64;
    Dec(Count);
  end;
end;

procedure ScatterMountains(Level: byte);
var
  Count: word;

begin
  Count := MountainAttempts[Level, Game.GenerationIsland];
  while Count > 0 do
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 80;
    Dec(Count);
  end;
end;

procedure ScatterSand(Level: byte);
var
  Count: word;

begin
  Count := SandAttempts[Level, Game.GenerationIsland];
  while Count > 0 do
  begin
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 32;
    Dec(Count);
  end;
end;

procedure PaintDesertRim;
var
  X, Y: byte;

begin
  for Y := 5 to 60 do Game.Map[Game.GenerationIsland, 5, Y] := 0;
  for Y := 5 to 60 do Game.Map[Game.GenerationIsland, 60, Y] := 0;

  for X := 6 to 59 do Game.Map[Game.GenerationIsland, X, 5] := 0;
  for X := 6 to 59 do Game.Map[Game.GenerationIsland, X, 60] := 0;
  for X := 6 to DesertRimExtent do
    for Y := 6 to 59 do Game.Map[Game.GenerationIsland, X, Y] := 32;
  for X := 65 - DesertRimExtent to 59 do
    for Y := 6 to 59 do Game.Map[Game.GenerationIsland, X, Y] := 32;
  for Y := 6 to DesertRimExtent do
    for X := DesertRimExtent to 65 - DesertRimExtent do Game.Map[Game.GenerationIsland, X, Y] := 32;
  for Y := 65 - DesertRimExtent to 59 do
    for X := DesertRimExtent to 65 - DesertRimExtent do Game.Map[Game.GenerationIsland, X, Y] := 32;
end;

procedure PaintRiversAndSea(Level: byte);
var
  X, Y: byte;

begin
  SelectRiverStart;
  CarveRiver(Level);

  for X := 0 to 4 do
    for Y := 0 to 65 do Game.Map[Game.GenerationIsland, X, Y] := 48;
  for X := 65 downto 61 do
    for Y := 0 to 65 do Game.Map[Game.GenerationIsland, X, Y] := 48;
  for Y := 0 to 4 do
    for X := 5 to 60 do Game.Map[Game.GenerationIsland, X, Y] := 48;
  for Y := 65 downto 61 do
    for X := 5 to 60 do Game.Map[Game.GenerationIsland, X, Y] := 48;
end;

procedure FrameTerrain(Base: byte; RemoveIsolated: boolean);
var
  X, Y, Frame: byte;

begin
  for X := 1 to 64 do
    for Y := 1 to 64 do
      if Game.Map[Game.GenerationIsland, X, Y] = Base then
      begin
        Frame := Base;

        if (Game.Map[Game.GenerationIsland, X, Y - 1] >= Base) and
           (Game.Map[Game.GenerationIsland, X, Y - 1] < Base + 16) then Frame := Frame + 1;
        if (Game.Map[Game.GenerationIsland, X, Y + 1] >= Base) and
           (Game.Map[Game.GenerationIsland, X, Y + 1] < Base + 16) then Frame := Frame + 2;
        if (Game.Map[Game.GenerationIsland, X - 1, Y] >= Base) and
           (Game.Map[Game.GenerationIsland, X - 1, Y] < Base + 16) then Frame := Frame + 4;
        if (Game.Map[Game.GenerationIsland, X + 1, Y] >= Base) and
           (Game.Map[Game.GenerationIsland, X + 1, Y] < Base + 16) then Frame := Frame + 8;
        if RemoveIsolated and (Frame = Base) then Game.Map[Game.GenerationIsland, X, Y] := 0
        else Game.Map[Game.GenerationIsland, X, Y] := Frame;
      end;
end;

procedure GenerateContracts;
label
  Found;

var
  NameIndex, RowIsland, RowSlot, FoundIsland, FoundSlot: byte;

begin
  NameIndex := 0;
  for RowIsland := 1 to 5 do
    for RowSlot := 1 to 5 do
    begin
      while Game.CastleNamePool[NameIndex] < 255 do Inc(NameIndex);

      for FoundIsland := 1 to 5 do
        for FoundSlot := 1 to 5 do
          if Game.Castles[FoundIsland, FoundSlot].Name = NameIndex then goto Found;
    Found:
      Game.Contracts[RowIsland, RowSlot].Island := FoundIsland;
      Game.Contracts[RowIsland, RowSlot].Slot := FoundSlot;
      Inc(NameIndex);
    end;
end;

{$I WORLDGEN.INC}

procedure PlaceInitialHero(Level: byte);
label
  Found;

var
  DX, DY: shortint;

begin
  if Level = 0 then
  begin
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if Game.Map[1, Game.Towns[1, 1].X + DX, Game.Towns[1, 1].Y + DY] = 0 then goto Found;
  Found:
    Game.Hero.X := Game.Towns[1, 1].X + DX;
    Game.Hero.Y := Game.Towns[1, 1].Y + DY;
  end
  else if Level = 1 then
  begin
    Game.Hero.X := Game.Castles[1, 1].X;
    Game.Hero.Y := Game.Castles[1, 1].Y + 1;
  end
  else
    repeat
      Game.Hero.X := Random(65);
      Game.Hero.Y := Random(65);
    until Game.Map[1, Game.Hero.X, Game.Hero.Y] = 0;
end;

end.
