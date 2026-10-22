unit KBGen;
{$G+,R-,S-,I+,A+}

interface

procedure PrepareCampaign(Level: byte);
procedure GenerateWorld(Level: byte);
procedure PlaceInitialHero(Level: byte);

implementation

uses KBRandom, KBTables, Crt, KBState;

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
    lea di, Game.Campaign.Map
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
  FillChar(Game.Campaign.WanderingArmies, SizeOf(Game.Campaign.WanderingArmies), 100);
  FillChar(Game.Campaign.Army, SizeOf(Game.Campaign.Army), 100);
  FillChar(Game.Campaign.Scrolls, SizeOf(Game.Campaign.Scrolls), 0);
  FillChar(Game.Campaign.Flags.Discovery, SizeOf(Game.Campaign.Flags.Discovery), 0);
  FillChar(Game.Campaign.Flags.LocalMapOwned, SizeOf(Game.Campaign.Flags.LocalMapOwned), 0);
  FillChar(Game.Campaign.WizardRelations, SizeOf(Game.Campaign.WizardRelations), 0);
  FillChar(Game.Campaign.WizardVisited, SizeOf(Game.Campaign.WizardVisited), 0);
  FillChar(Game.Campaign.Cargo, SizeOf(Game.Campaign.Cargo), 0);
  FillChar(Game.Campaign.CargoMaxPrices, SizeOf(Game.Campaign.CargoMaxPrices), 0);
  FillChar(Game.Campaign.VisitedCastles, SizeOf(Game.Campaign.VisitedCastles), 0);
  FillChar(Game.Campaign.VisitedTowns, SizeOf(Game.Campaign.VisitedTowns), 0);
  FillChar(Game.Campaign.QuestFlags, SizeOf(Game.Campaign.QuestFlags), 3);
  FillChar(Game.Campaign.Flags.SpellAvailable, SizeOf(Game.Campaign.Flags.SpellAvailable), 0);
  FillChar(Game.Campaign.Flags.SpellUsed, SizeOf(Game.Campaign.Flags.SpellUsed), 0);
  Game.Campaign.Mutants[25].Name := 'åìêãÄçíõ1';
  Game.Campaign.Mutants[26].Name := 'åìêãÄçíõ2';
  Game.Campaign.Mutants[27].Name := 'åìêãÄçíõ3';
  Game.Campaign.Mutants[28].Name := 'åìêãÄçíõ4';
  Game.Campaign.Mutants[29].Name := 'åìêãÄçíõ5';

  for I := 0 to 27 do
  begin
    Game.World.TownNamePool[I] := I;
    Game.World.CastleNamePool[I] := I;
  end;

  for I := 0 to 7 do Game.World.SpellColorPool[I] := I;
  for I := 2 to 5 do Game.Campaign.Relics[I].Owned := false;
  Game.Campaign.Relics[2].Artwork := 26;
  Game.Campaign.Relics[3].Artwork := 25;
  Game.Campaign.Relics[4].Artwork := 24;
  Game.Campaign.Relics[5].Artwork := 27;
  Game.Campaign.HighestVisitedIsland := 1;
  Game.Campaign.UnlockedIslands := 1;
  Game.Campaign.ContractIsland := 100;
  Game.Campaign.HiddenSpellIsland := 100;
  Game.Campaign.RitualStoneIsland := 100;
  Game.Campaign.DamageBonus := 0;
  Game.Campaign.LeadershipBonus := 0;

  case Level of
    0: begin
      Game.Campaign.Carpenters := 4;
      Game.Campaign.Woodcutters := 6;
      Game.Campaign.Diggers := 0;
      Game.Campaign.Stonecutters := 3;
      Game.Campaign.Difficulty := 6;
      Game.Campaign.MagicPower := 1;
      Game.Campaign.Gold := 20000;
      Game.Campaign.ScrollCapacity := 4;
    end;

    1: begin
      Game.Campaign.Carpenters := 4;
      Game.Campaign.Woodcutters := 4;
      Game.Campaign.Diggers := 0;
      Game.Campaign.Stonecutters := 2;
      Game.Campaign.Difficulty := 5;
      Game.Campaign.MagicPower := 1;
      Game.Campaign.Gold := 15000;
      Game.Campaign.ScrollCapacity := 3;
    end;

    2: begin
      Game.Campaign.Carpenters := 2;
      Game.Campaign.Woodcutters := 3;
      Game.Campaign.Diggers := 0;
      Game.Campaign.Stonecutters := 0;
      Game.Campaign.Difficulty := 4;
      Game.Campaign.MagicPower := 0;
      Game.Campaign.Gold := 10000;
      Game.Campaign.ScrollCapacity := 2;
    end;

    3: begin
      Game.Campaign.Carpenters := 2;
      Game.Campaign.Woodcutters := 2;
      Game.Campaign.Diggers := 0;
      Game.Campaign.Stonecutters := 0;
      Game.Campaign.Difficulty := 3;
      Game.Campaign.MagicPower := 0;
      Game.Campaign.RitualPower := 0;
      Game.Campaign.Gold := 0;
      Game.Campaign.ScrollCapacity := 2;
    end;
  end;

  Game.Campaign.ExtraDays := 0;
  Game.Campaign.Flags.ShipOwned := false;
  Game.Campaign.Flags.SiegeEngineOwned := false;
  Game.Campaign.Flags.ArmyAvailable := false;
  Game.Campaign.Flags.InstructionsShown := false;

  for I := 1 to 4 do
  begin
    Game.World.GenerationX := Random(20);

    if Game.World.GenerationX < 10 then Game.Campaign.Flags.PaperChartPresent[I] := false
    else Game.Campaign.Flags.PaperChartPresent[I] := true;
  end;

  Game.Campaign.Flags.PaperChartPresent[5] := false;
  Game.Campaign.SceneIsland := 1;
  Game.Campaign.ShipHeading := 1;
  RandomizeGame;

  for I := 0 to 7 do
  begin
    repeat
      Game.World.GenerationX := Random(79) div 10;
    until Game.World.SpellColorPool[Game.World.GenerationX] <> 255;
    Game.Campaign.SpellColors[I] := Game.World.GenerationX;
    Game.World.SpellColorPool[Game.World.GenerationX] := 255;
  end;

  Game.Campaign.Island := 1;
  Game.Campaign.Weeks := InitialWeekLimits[Level];
  Game.Campaign.Days := 200;
  Game.Campaign.Income := 500;
  Game.Campaign.Leadership := 50;
  Game.Campaign.EnemyGrace := 40;
  Game.Campaign.MapParts := 0;
  Game.Campaign.TornadoCharges := 0;
  Game.Campaign.Flags.Heading := true;
end;

procedure SelectRiverStart;
begin
  Game.World.GenerationChoice := Random(50);
  if Game.World.GenerationChoice < 12 then
  begin
    Game.World.GenerationX := 5;
    Game.World.GenerationY := Random(65);
  end
  else if Game.World.GenerationChoice < 25 then
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := 65;
  end
  else if Game.World.GenerationChoice < 37 then
  begin
    Game.World.GenerationX := 65;
    Game.World.GenerationY := Random(65);
  end
  else
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := 5;
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
  Budget := RiverBudgets[Level, Game.World.GenerationIsland];

  while Budget > 2 do
  begin
  RetryTarget:
    TargetX := Random(65);
    TargetY := Random(65);

    if (Abs(TargetX - Game.World.GenerationX) > 15) or (Abs(TargetY - Game.World.GenerationY) > 15) then goto
    RetryTarget;
    Minor := TargetY - Game.World.GenerationY;
    if Minor < 0 then
    begin
      StepY := -1;
      Minor := -Minor;
    end
    else StepY := 1;
    DiagonalY := StepY;
    Major := TargetX - Game.World.GenerationX;

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
      if Game.World.GenerationX < 5 then Game.World.GenerationX := 5;

      if Game.World.GenerationY < 5 then Game.World.GenerationY := 5;
      if Game.World.GenerationX > 64 then Game.World.GenerationX := 64;
      if Game.World.GenerationY > 64 then Game.World.GenerationY := 64;
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 48;
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY] := 48;
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY + 1] := 48;

      if Error < 0 then
      begin
        Game.World.GenerationX := Game.World.GenerationX + StepX;
        Game.World.GenerationY := Game.World.GenerationY + StepY;
        Error := Error + StraightIncrement;
      end
      else
      begin
        if AlternateX then Game.World.GenerationX := Game.World.GenerationX + DiagonalX
        else
        begin
          Game.World.GenerationY := Game.World.GenerationY + DiagonalY;
          Error := Error + DiagonalIncrement;
        end;

        AlternateX := not AlternateX;
      end;

      Dec(Budget, 3);
      Dec(Major);
    end;

    Game.World.GenerationX := TargetX;
    Game.World.GenerationY := TargetY;
  end;
end;

procedure ScatterGrass(Level: byte);
var
  Count: word;

begin
  Count := GrassAttempts[Level, Game.World.GenerationIsland];
  while Count > 0 do
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 0;
    Dec(Count);
  end;
end;

procedure ScatterForest(Level: byte);
var
  Count: word;

begin
  Count := ForestAttempts[Level, Game.World.GenerationIsland];
  while Count > 0 do
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 64;
    Dec(Count);
  end;
end;

procedure ScatterMountains(Level: byte);
var
  Count: word;

begin
  Count := MountainAttempts[Level, Game.World.GenerationIsland];
  while Count > 0 do
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 80;
    Dec(Count);
  end;
end;

procedure ScatterSand(Level: byte);
var
  Count: word;

begin
  Count := SandAttempts[Level, Game.World.GenerationIsland];
  while Count > 0 do
  begin
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 32;
    Dec(Count);
  end;
end;

procedure PaintDesertRim;
var
  X, Y: byte;

begin
  for Y := 5 to 60 do Game.Campaign.Map[Game.World.GenerationIsland, 5, Y] := 0;
  for Y := 5 to 60 do Game.Campaign.Map[Game.World.GenerationIsland, 60, Y] := 0;

  for X := 6 to 59 do Game.Campaign.Map[Game.World.GenerationIsland, X, 5] := 0;
  for X := 6 to 59 do Game.Campaign.Map[Game.World.GenerationIsland, X, 60] := 0;
  for X := 6 to DesertRimExtent do
    for Y := 6 to 59 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 32;
  for X := 65 - DesertRimExtent to 59 do
    for Y := 6 to 59 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 32;
  for Y := 6 to DesertRimExtent do
    for X := DesertRimExtent to 65 - DesertRimExtent do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 32;
  for Y := 65 - DesertRimExtent to 59 do
    for X := DesertRimExtent to 65 - DesertRimExtent do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 32;
end;

procedure PaintRiversAndSea(Level: byte);
var
  X, Y: byte;

begin
  SelectRiverStart;
  CarveRiver(Level);

  for X := 0 to 4 do
    for Y := 0 to 65 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 48;
  for X := 65 downto 61 do
    for Y := 0 to 65 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 48;
  for Y := 0 to 4 do
    for X := 5 to 60 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 48;
  for Y := 65 downto 61 do
    for X := 5 to 60 do Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 48;
end;

procedure FrameTerrain(Base: byte; RemoveIsolated: boolean);
var
  X, Y, Frame: byte;

begin
  for X := 1 to 64 do
    for Y := 1 to 64 do
      if Game.Campaign.Map[Game.World.GenerationIsland, X, Y] = Base then
      begin
        Frame := Base;

        if (Game.Campaign.Map[Game.World.GenerationIsland, X, Y - 1] >= Base) and
           (Game.Campaign.Map[Game.World.GenerationIsland, X, Y - 1] < Base + 16) then Frame := Frame + 1;
        if (Game.Campaign.Map[Game.World.GenerationIsland, X, Y + 1] >= Base) and
           (Game.Campaign.Map[Game.World.GenerationIsland, X, Y + 1] < Base + 16) then Frame := Frame + 2;
        if (Game.Campaign.Map[Game.World.GenerationIsland, X - 1, Y] >= Base) and
           (Game.Campaign.Map[Game.World.GenerationIsland, X - 1, Y] < Base + 16) then Frame := Frame + 4;
        if (Game.Campaign.Map[Game.World.GenerationIsland, X + 1, Y] >= Base) and
           (Game.Campaign.Map[Game.World.GenerationIsland, X + 1, Y] < Base + 16) then Frame := Frame + 8;
        if RemoveIsolated and (Frame = Base) then Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := 0
        else Game.Campaign.Map[Game.World.GenerationIsland, X, Y] := Frame;
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
      while Game.World.CastleNamePool[NameIndex] < 255 do Inc(NameIndex);

      for FoundIsland := 1 to 5 do
        for FoundSlot := 1 to 5 do
          if Game.Campaign.Castles[FoundIsland, FoundSlot].Name = NameIndex then goto Found;
    Found:
      Game.Campaign.Contracts[RowIsland, RowSlot].Island := FoundIsland;
      Game.Campaign.Contracts[RowIsland, RowSlot].Slot := FoundSlot;
      Inc(NameIndex);
    end;
end;

procedure GenerateWorld(Level: byte);

procedure GenerateCastles;
label
  RetrySite;

var
  Number, Index: byte;
  Strength: word;
  Value: longint;
begin
  for Number := 1 to 5 do
  begin
  RetrySite:
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);

    if (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 48) or
       (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX - 1, Game.World.GenerationY] = 48) or
       (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY] = 48)
    then goto RetrySite;
    if not (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0,
    32, 64, 80]) then goto RetrySite;

    for Index := 1 to Number do
      if (Game.Campaign.Castles[Game.World.GenerationIsland, Index].X < Game.World.GenerationX + 5) and
         (Game.Campaign.Castles[Game.World.GenerationIsland, Index].X > Game.World.GenerationX - 5) and
         (Game.Campaign.Castles[Game.World.GenerationIsland, Index].Y < Game.World.GenerationY + 5) and
         (Game.Campaign.Castles[Game.World.GenerationIsland, Index].Y > Game.World.GenerationY - 5) then goto
    RetrySite;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 2;
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].X := Game.World.GenerationX;
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].Y := Game.World.GenerationY;
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].Owned := false;
  end;

  for Number := 1 to 5 do
  begin
    Game.World.GenerationX := Game.Campaign.Castles[Game.World.GenerationIsland, Number].X;
    Game.World.GenerationY := Game.Campaign.Castles[Game.World.GenerationIsland, Number].Y;

    repeat
      Index := Random(279) div 10
    until Game.World.CastleNamePool[Index] <> 255;
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].Name := Index;
    Game.World.CastleNamePool[Index] := 255;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY + 1] := 5;
    Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number - 1].X := Game.World.GenerationX;
    Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number - 1].Y := Game.World.GenerationY + 1;

    if Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX - 1, Game.World.GenerationY + 1] <> 48
    then
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX - 1, Game.World.GenerationY + 1] := 0;
    if Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY + 1] <> 48
    then
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY + 1] := 0;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX - 1, Game.World.GenerationY] := 1;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY] := 3;
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].Value := 0;

    for Index := 0 to 4 do
    begin
      repeat
        Strength := Random(WanderingArmyBudgets[Level, Game.World.GenerationIsland]) +
                  WanderingArmyBudgets[Level, Game.World.GenerationIsland];
        if (Number = 1) and (Index = 0) then
        begin
          Game.Campaign.Castles[Game.World.GenerationIsland, Number].Species[Index] := 23;
          Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index] :=
            Game.World.GenerationIsland * GuardianDragonCounts[Level];
        end
        else
        begin
          Game.World.GenerationChoice := Random(24);

          if Game.World.GenerationIsland > 2 then
          begin
            if Game.World.GenerationChoice > 19 then Game.World.GenerationChoice := 19;
            Game.Campaign.Castles[Game.World.GenerationIsland, Number].Species[Index] :=
    Game.World.GenerationChoice + 5;
          end
          else Game.Campaign.Castles[Game.World.GenerationIsland, Number].Species[Index] :=
    Game.World.GenerationChoice;
          Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index] :=
            Strength div CreatureDefinitions[Game.Campaign.Castles[Game.World.GenerationIsland,
    Number].Species[Index]].Defense;
        end;
      until Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index] >= 2;

      if Number = 1 then Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index] :=
        Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index] * 2;
      Value := CreatureDefinitions[Game.Campaign.Castles[Game.World.GenerationIsland,
    Number].Species[Index]].Cost.Price;
      Value := Value * Game.Campaign.Castles[Game.World.GenerationIsland, Number].Counts[Index];
      Game.Campaign.Castles[Game.World.GenerationIsland, Number].Value :=
    Game.Campaign.Castles[Game.World.GenerationIsland, Number].Value + Value;
    end;
  end;
end;

procedure GenerateTowns;
label
  RetrySite;

var
  Number, NameIndex, OfferIndex: byte;
  DX, DY: shortint;
begin
  for Number := 1 to 5 do
  begin
  RetrySite:
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);

    if Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] <> 48 then
    goto RetrySite;
    DX := 1;
    DY := 1;

    while Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 48 do
    begin
      Game.World.GenerationX := Game.World.GenerationX + DX;
      Game.World.GenerationY := Game.World.GenerationY + DY;

      if Game.World.GenerationX < 5 then
      begin
        Game.World.GenerationX := 5;
        DX := 1
      end;

      if Game.World.GenerationX > 60 then
      begin
        Game.World.GenerationX := 60;
        DX := -1
      end;

      if Game.World.GenerationY > 60 then
      begin
        Game.World.GenerationY := 60;
        DY := -1
      end;

      if Game.World.GenerationY < 5 then
      begin
        Game.World.GenerationY := 5;
        DY := 1
      end;
    end;

    if not (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0,
    32, 64, 80]) then goto RetrySite;
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].X := Game.World.GenerationX;
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Y := Game.World.GenerationY;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 7;

    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + DX, Game.World.GenerationY + DY]
    > 48 then
          Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + DX, Game.World.GenerationY + DY]
    := 0;
    OfferIndex := Random(ScrollChoiceBounds[Game.World.GenerationIsland]) div 10;
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Scroll := ScrollChoiceOrder[OfferIndex];

    repeat
      NameIndex := Random(279) div 10
    until Game.World.TownNamePool[NameIndex] <> 255;
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Name := NameIndex;
    Game.World.TownNamePool[NameIndex] := 255;
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Workers[1] :=
    WorkerCapacities[Game.World.GenerationIsland, Number, 0];
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Workers[2] :=
    WorkerCapacities[Game.World.GenerationIsland, Number, 1];
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Workers[3] :=
    WorkerCapacities[Game.World.GenerationIsland, Number, 2];
    Game.Campaign.Towns[Game.World.GenerationIsland, Number].Workers[4] :=
    WorkerCapacities[Game.World.GenerationIsland, Number, 3];
  end;
end;

procedure GenerateUnderground;
begin
  if Game.World.GenerationIsland = 5 then
    repeat
      Game.World.GenerationX := Random(65);
      Game.World.GenerationY := Random(65);
    until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 80
  else
    repeat
      Game.World.GenerationX := Random(65);
      Game.World.GenerationY := Random(65);
    until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] <> 48;
  Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 11;
  Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY] := 0;
  Game.Campaign.Underground[Game.World.GenerationIsland, 1].X := Game.World.GenerationX;
  Game.Campaign.Underground[Game.World.GenerationIsland, 1].Y := Game.World.GenerationY;

  if Game.World.GenerationIsland = 5 then
    repeat
      Game.World.GenerationX := Random(65);
      Game.World.GenerationY := Random(65);
    until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 80
  else
    repeat
      Game.World.GenerationX := Random(65);
      Game.World.GenerationY := Random(65);
    until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] <> 48;
  Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 11;
  Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX + 1, Game.World.GenerationY] := 0;
  Game.Campaign.Underground[Game.World.GenerationIsland, 2].X := Game.World.GenerationX;
  Game.Campaign.Underground[Game.World.GenerationIsland, 2].Y := Game.World.GenerationY;
end;

procedure GenerateDwellings;
label
  RetrySite;

var
  Number, Species: byte;

begin
  for Number := 0 to 7 do
  begin
  RetrySite:
    Game.World.GenerationX := Random(Game.World.GenerationCount);
    Game.World.GenerationY := Random(Game.World.GenerationLimit);
    Inc(Game.World.GenerationX, 5);
    Inc(Game.World.GenerationY, 5);

    if Game.World.GenerationIsland = 5 then
      if not (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0,
    80]) then goto RetrySite;
    Game.Campaign.Dwellings[Game.World.GenerationIsland, Number].X := Game.World.GenerationX;
    Game.Campaign.Dwellings[Game.World.GenerationIsland, Number].Y := Game.World.GenerationY;
    Species := WanderingSpeciesBases[Game.World.GenerationIsland] + Random(148) div 10;

    if Species > WanderingSpeciesBases[Game.World.GenerationIsland] + 9 then Dec(Species, 5);
    if Species < 10 then Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX,
    Game.World.GenerationY] := 8
    else Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 0;
    Game.Campaign.Dwellings[Game.World.GenerationIsland, Number].Species := Species;
    Game.Campaign.Dwellings[Game.World.GenerationIsland, Number].Count := WeeklyDwellingCapacities[Species];
  end;
end;

procedure GenerateTalkingStones;
label
  RetrySite;

var
  Number: byte;

begin
  for Number := 0 to 5 do
  begin
  RetrySite:
    Game.World.GenerationX := Random(Game.World.GenerationCount);
    Game.World.GenerationY := Random(Game.World.GenerationLimit);
    Inc(Game.World.GenerationX, 5);
    Inc(Game.World.GenerationY, 5);

    if Game.World.GenerationIsland = 5 then
      if not (Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0,
    80]) then goto RetrySite;
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 22;
  end;
end;

procedure GenerateWanderingArmies;
var
  Number, Slot, Species: byte;
  Strength: word;
begin
  for Number := 0 to 20 do
  begin
    if Game.World.GenerationIsland = 5 then
      repeat
        Game.World.GenerationX := Random(65);
        Game.World.GenerationY := Random(65);
      until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 80
    else
      repeat
        Game.World.GenerationX := Random(65);
        Game.World.GenerationY := Random(65);
      until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] <> 48;
    if Number > 4 then
    begin
      Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 5;
      Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number].X := Game.World.GenerationX;
      Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number].Y := Game.World.GenerationY;
    end;

    Strength := Random(WanderingArmyBudgets[Level, Game.World.GenerationIsland]);
    Inc(Strength, 10);
    for Slot := 0 to 2 do
    begin
      Species := WanderingSpeciesBases[Game.World.GenerationIsland] + Random(148) div 10;

      if Species > WanderingSpeciesBases[Game.World.GenerationIsland] + 9 then Dec(Species, 5);
      Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number].Counts[Slot] := Strength div
    CreatureDefinitions[Species]
        .Defense;
      if Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number].Counts[Slot] > 2 then
        Game.Campaign.WanderingArmies[Game.World.GenerationIsland, Number].Species[Slot] := Species;
    end;
  end;
end;

procedure GeneratePaperScrolls;
var
  Number: byte;

begin
  for Number := 1 to 2 do
  begin
    if Game.World.GenerationIsland = 5 then
      repeat
        Game.World.GenerationX := Random(65);
        Game.World.GenerationY := Random(65);
      until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] = 80
    else
      repeat
        Game.World.GenerationX := Random(Game.World.GenerationCount);
        Game.World.GenerationY := Random(Game.World.GenerationLimit);
        Inc(Game.World.GenerationX, 5);
        Inc(Game.World.GenerationY, 5);
      until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0,
    32, 48, 64, 80];
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 9;
  end;
end;

procedure GenerateTreasures;
var
  Number: byte;

begin
  for Number := 1 to 30 do
  begin
    repeat
      Game.World.GenerationX := Random(Game.World.GenerationCount);
      Game.World.GenerationY := Random(Game.World.GenerationLimit);
      Inc(Game.World.GenerationX, 5);
      Inc(Game.World.GenerationY, 5);
    until Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] in [0, 32,
    48, 64, 80];
    Game.Campaign.Map[Game.World.GenerationIsland, Game.World.GenerationX, Game.World.GenerationY] := 10;
  end;
end;

procedure PaintOuterFrame;
var
  X, Y: byte;

begin
  for X := 0 to 65 do
  begin
    Game.Campaign.Map[Game.World.GenerationIsland, X, 0] := 63;
    Game.Campaign.Map[Game.World.GenerationIsland, X, 65] := 63;
  end;

  for Y := 0 to 65 do
  begin
    Game.Campaign.Map[Game.World.GenerationIsland, 0, Y] := 63;
    Game.Campaign.Map[Game.World.GenerationIsland, 65, Y] := 63;
  end;
end;

begin
  Game.World.GenerationCount := 55;
  Game.World.GenerationLimit := 55;

  for Game.World.GenerationIsland := 1 to 5 do
  begin
    RandomizeGame;

    if Game.World.GenerationIsland > 1 then ScatterGrass(Level);
    if Game.World.GenerationIsland <> 3 then ScatterForest(Level);
    if Game.World.GenerationIsland < 4 then ScatterMountains(Level);

    if Game.World.GenerationIsland = 5 then PaintDesertRim
    else ScatterSand(Level);
    PaintRiversAndSea(Level);
    GenerateTalkingStones;
    GenerateWanderingArmies;
    GenerateTreasures;
    GenerateUnderground;
    GenerateDwellings;
    GenerateTowns;
    GenerateCastles;
    GeneratePaperScrolls;
    PaintOuterFrame;
    FrameTerrain(48, false);
    FrameTerrain(32, true);

    if Level < 2 then FrameTerrain(64, true)
    else if Game.World.GenerationIsland = 4 then FrameTerrain(64, false)
    else FrameTerrain(64, true);

    if Level < 2 then FrameTerrain(80, true)
    else if Game.World.GenerationIsland in [4, 5] then FrameTerrain(80, false)
    else FrameTerrain(80, true);
  end;

  GenerateContracts;
end;

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
        if Game.Campaign.Map[1, Game.Campaign.Towns[1, 1].X + DX, Game.Campaign.Towns[1, 1].Y + DY] = 0 then goto
    Found;
  Found:
    Game.Campaign.Hero.X := Game.Campaign.Towns[1, 1].X + DX;
    Game.Campaign.Hero.Y := Game.Campaign.Towns[1, 1].Y + DY;
  end
  else if Level = 1 then
  begin
    Game.Campaign.Hero.X := Game.Campaign.Castles[1, 1].X;
    Game.Campaign.Hero.Y := Game.Campaign.Castles[1, 1].Y + 1;
  end
  else
    repeat
      Game.Campaign.Hero.X := Random(65);
      Game.Campaign.Hero.Y := Random(65);
    until Game.Campaign.Map[1, Game.Campaign.Hero.X, Game.Campaign.Hero.Y] = 0;
end;
end.
