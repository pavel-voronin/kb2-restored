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
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);

    if (Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 48) or
       (Game.Map[Game.GenerationIsland, Game.GenerationX - 1, Game.GenerationY] = 48) or
       (Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY] = 48) then goto RetrySite;
    if not (Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 32, 64, 80]) then goto RetrySite;

    for Index := 1 to Number do
      if (Game.Castles[Game.GenerationIsland, Index].X < Game.GenerationX + 5) and
         (Game.Castles[Game.GenerationIsland, Index].X > Game.GenerationX - 5) and
         (Game.Castles[Game.GenerationIsland, Index].Y < Game.GenerationY + 5) and
         (Game.Castles[Game.GenerationIsland, Index].Y > Game.GenerationY - 5) then goto RetrySite;
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 2;
    Game.Castles[Game.GenerationIsland, Number].X := Game.GenerationX;
    Game.Castles[Game.GenerationIsland, Number].Y := Game.GenerationY;
    Game.Castles[Game.GenerationIsland, Number].Owned := false;
  end;

  for Number := 1 to 5 do
  begin
    Game.GenerationX := Game.Castles[Game.GenerationIsland, Number].X;
    Game.GenerationY := Game.Castles[Game.GenerationIsland, Number].Y;

    repeat
      Index := Random(279) div 10
    until Game.CastleNamePool[Index] <> 255;
    Game.Castles[Game.GenerationIsland, Number].Name := Index;
    Game.CastleNamePool[Index] := 255;
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY + 1] := 5;
    Game.WanderingArmies[Game.GenerationIsland, Number - 1].X := Game.GenerationX;
    Game.WanderingArmies[Game.GenerationIsland, Number - 1].Y := Game.GenerationY + 1;

    if Game.Map[Game.GenerationIsland, Game.GenerationX - 1, Game.GenerationY + 1] <> 48 then
      Game.Map[Game.GenerationIsland, Game.GenerationX - 1, Game.GenerationY + 1] := 0;
    if Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY + 1] <> 48 then
      Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY + 1] := 0;
    Game.Map[Game.GenerationIsland, Game.GenerationX - 1, Game.GenerationY] := 1;
    Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY] := 3;
    Game.Castles[Game.GenerationIsland, Number].Value := 0;

    for Index := 0 to 4 do
    begin
      repeat
        Strength := Random(WanderingArmyBudgets[Level, Game.GenerationIsland]) +
                  WanderingArmyBudgets[Level, Game.GenerationIsland];
        if (Number = 1) and (Index = 0) then
        begin
          Game.Castles[Game.GenerationIsland, Number].Species[Index] := 23;
          Game.Castles[Game.GenerationIsland, Number].Counts[Index] :=
            Game.GenerationIsland * GuardianDragonCounts[Level];
        end
        else
        begin
          Game.GenerationChoice := Random(24);

          if Game.GenerationIsland > 2 then
          begin
            if Game.GenerationChoice > 19 then Game.GenerationChoice := 19;
            Game.Castles[Game.GenerationIsland, Number].Species[Index] := Game.GenerationChoice + 5;
          end
          else Game.Castles[Game.GenerationIsland, Number].Species[Index] := Game.GenerationChoice;
          Game.Castles[Game.GenerationIsland, Number].Counts[Index] :=
            Strength div CreatureDefinitions[Game.Castles[Game.GenerationIsland, Number].Species[Index]].Defense;
        end;
      until Game.Castles[Game.GenerationIsland, Number].Counts[Index] >= 2;

      if Number = 1 then Game.Castles[Game.GenerationIsland, Number].Counts[Index] :=
        Game.Castles[Game.GenerationIsland, Number].Counts[Index] * 2;
      Value := CreatureDefinitions[Game.Castles[Game.GenerationIsland, Number].Species[Index]].Cost.Price;
      Value := Value * Game.Castles[Game.GenerationIsland, Number].Counts[Index];
      Game.Castles[Game.GenerationIsland, Number].Value := Game.Castles[Game.GenerationIsland, Number].Value + Value;
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
    Game.GenerationX := Random(65);
    Game.GenerationY := Random(65);

    if Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] <> 48 then goto RetrySite;
    DX := 1;
    DY := 1;

    while Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 48 do
    begin
      Game.GenerationX := Game.GenerationX + DX;
      Game.GenerationY := Game.GenerationY + DY;

      if Game.GenerationX < 5 then
      begin
        Game.GenerationX := 5;
        DX := 1
      end;

      if Game.GenerationX > 60 then
      begin
        Game.GenerationX := 60;
        DX := -1
      end;

      if Game.GenerationY > 60 then
      begin
        Game.GenerationY := 60;
        DY := -1
      end;

      if Game.GenerationY < 5 then
      begin
        Game.GenerationY := 5;
        DY := 1
      end;
    end;

    if not (Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 32, 64, 80]) then goto RetrySite;
    Game.Towns[Game.GenerationIsland, Number].X := Game.GenerationX;
    Game.Towns[Game.GenerationIsland, Number].Y := Game.GenerationY;
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 7;

    for DX := -1 to 1 do
      for DY := -1 to 1 do
        if Game.Map[Game.GenerationIsland, Game.GenerationX + DX, Game.GenerationY + DY] > 48 then
          Game.Map[Game.GenerationIsland, Game.GenerationX + DX, Game.GenerationY + DY] := 0;
    OfferIndex := Random(ScrollChoiceBounds[Game.GenerationIsland]) div 10;
    Game.Towns[Game.GenerationIsland, Number].Scroll := ScrollChoiceOrder[OfferIndex];

    repeat
      NameIndex := Random(279) div 10
    until Game.TownNamePool[NameIndex] <> 255;
    Game.Towns[Game.GenerationIsland, Number].Name := NameIndex;
    Game.TownNamePool[NameIndex] := 255;
    Game.Towns[Game.GenerationIsland, Number].Workers[1] := WorkerCapacities[Game.GenerationIsland, Number, 0];
    Game.Towns[Game.GenerationIsland, Number].Workers[2] := WorkerCapacities[Game.GenerationIsland, Number, 1];
    Game.Towns[Game.GenerationIsland, Number].Workers[3] := WorkerCapacities[Game.GenerationIsland, Number, 2];
    Game.Towns[Game.GenerationIsland, Number].Workers[4] := WorkerCapacities[Game.GenerationIsland, Number, 3];
  end;
end;

procedure GenerateUnderground;
begin
  if Game.GenerationIsland = 5 then
    repeat
      Game.GenerationX := Random(65);
      Game.GenerationY := Random(65);
    until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 80
  else
    repeat
      Game.GenerationX := Random(65);
      Game.GenerationY := Random(65);
    until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] <> 48;
  Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 11;
  Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY] := 0;
  Game.Underground[Game.GenerationIsland, 1].X := Game.GenerationX;
  Game.Underground[Game.GenerationIsland, 1].Y := Game.GenerationY;

  if Game.GenerationIsland = 5 then
    repeat
      Game.GenerationX := Random(65);
      Game.GenerationY := Random(65);
    until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 80
  else
    repeat
      Game.GenerationX := Random(65);
      Game.GenerationY := Random(65);
    until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] <> 48;
  Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 11;
  Game.Map[Game.GenerationIsland, Game.GenerationX + 1, Game.GenerationY] := 0;
  Game.Underground[Game.GenerationIsland, 2].X := Game.GenerationX;
  Game.Underground[Game.GenerationIsland, 2].Y := Game.GenerationY;
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
    Game.GenerationX := Random(Game.GenerationCount);
    Game.GenerationY := Random(Game.GenerationLimit);
    Inc(Game.GenerationX, 5);
    Inc(Game.GenerationY, 5);

    if Game.GenerationIsland = 5 then
      if not (Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 80]) then goto RetrySite;
    Game.Dwellings[Game.GenerationIsland, Number].X := Game.GenerationX;
    Game.Dwellings[Game.GenerationIsland, Number].Y := Game.GenerationY;
    Species := WanderingSpeciesBases[Game.GenerationIsland] + Random(148) div 10;

    if Species > WanderingSpeciesBases[Game.GenerationIsland] + 9 then Dec(Species, 5);
    if Species < 10 then Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 8
    else Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 0;
    Game.Dwellings[Game.GenerationIsland, Number].Species := Species;
    Game.Dwellings[Game.GenerationIsland, Number].Count := WeeklyDwellingCapacities[Species];
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
    Game.GenerationX := Random(Game.GenerationCount);
    Game.GenerationY := Random(Game.GenerationLimit);
    Inc(Game.GenerationX, 5);
    Inc(Game.GenerationY, 5);

    if Game.GenerationIsland = 5 then
      if not (Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 80]) then goto RetrySite;
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 22;
  end;
end;

procedure GenerateWanderingArmies;
var
  Number, Slot, Species: byte;
  Strength: word;
begin
  for Number := 0 to 20 do
  begin
    if Game.GenerationIsland = 5 then
      repeat
        Game.GenerationX := Random(65);
        Game.GenerationY := Random(65);
      until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 80
    else
      repeat
        Game.GenerationX := Random(65);
        Game.GenerationY := Random(65);
      until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] <> 48;
    if Number > 4 then
    begin
      Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 5;
      Game.WanderingArmies[Game.GenerationIsland, Number].X := Game.GenerationX;
      Game.WanderingArmies[Game.GenerationIsland, Number].Y := Game.GenerationY;
    end;

    Strength := Random(WanderingArmyBudgets[Level, Game.GenerationIsland]);
    Inc(Strength, 10);
    for Slot := 0 to 2 do
    begin
      Species := WanderingSpeciesBases[Game.GenerationIsland] + Random(148) div 10;

      if Species > WanderingSpeciesBases[Game.GenerationIsland] + 9 then Dec(Species, 5);
      Game.WanderingArmies[Game.GenerationIsland, Number].Counts[Slot] := Strength div CreatureDefinitions[Species]
        .Defense;
      if Game.WanderingArmies[Game.GenerationIsland, Number].Counts[Slot] > 2 then
        Game.WanderingArmies[Game.GenerationIsland, Number].Species[Slot] := Species;
    end;
  end;
end;

procedure GeneratePaperScrolls;
var
  Number: byte;

begin
  for Number := 1 to 2 do
  begin
    if Game.GenerationIsland = 5 then
      repeat
        Game.GenerationX := Random(65);
        Game.GenerationY := Random(65);
      until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] = 80
    else
      repeat
        Game.GenerationX := Random(Game.GenerationCount);
        Game.GenerationY := Random(Game.GenerationLimit);
        Inc(Game.GenerationX, 5);
        Inc(Game.GenerationY, 5);
      until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 32, 48, 64, 80];
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 9;
  end;
end;

procedure GenerateTreasures;
var
  Number: byte;

begin
  for Number := 1 to 30 do
  begin
    repeat
      Game.GenerationX := Random(Game.GenerationCount);
      Game.GenerationY := Random(Game.GenerationLimit);
      Inc(Game.GenerationX, 5);
      Inc(Game.GenerationY, 5);
    until Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] in [0, 32, 48, 64, 80];
    Game.Map[Game.GenerationIsland, Game.GenerationX, Game.GenerationY] := 10;
  end;
end;

procedure PaintOuterFrame;
var
  X, Y: byte;

begin
  for X := 0 to 65 do
  begin
    Game.Map[Game.GenerationIsland, X, 0] := 63;
    Game.Map[Game.GenerationIsland, X, 65] := 63;
  end;

  for Y := 0 to 65 do
  begin
    Game.Map[Game.GenerationIsland, 0, Y] := 63;
    Game.Map[Game.GenerationIsland, 65, Y] := 63;
  end;
end;

begin
  Game.GenerationCount := 55;
  Game.GenerationLimit := 55;

  for Game.GenerationIsland := 1 to 5 do
  begin
    RandomizeGame;

    if Game.GenerationIsland > 1 then ScatterGrass(Level);
    if Game.GenerationIsland <> 3 then ScatterForest(Level);
    if Game.GenerationIsland < 4 then ScatterMountains(Level);

    if Game.GenerationIsland = 5 then PaintDesertRim
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
    else if Game.GenerationIsland = 4 then FrameTerrain(64, false)
    else FrameTerrain(64, true);

    if Level < 2 then FrameTerrain(80, true)
    else if Game.GenerationIsland in [4, 5] then FrameTerrain(80, false)
    else FrameTerrain(80, true);
  end;

  GenerateContracts;
end;
