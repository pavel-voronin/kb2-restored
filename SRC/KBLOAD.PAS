unit KBLoad;
{$G+,R-,S-,I+,A+}

interface

procedure PrepareLoadedCampaign;

implementation

uses KBAdvent, KBWorld, KBTables, KBArt, KBGfx, KBFiles, Crt, KBTypes, KBState;

procedure PrepareLoadedCampaign;
label
  SpiritFound;

var
  I, J: byte;
  UnknownLocal: word;
  Count: byte;
  Positions: array[1..2] of TPosition;

begin
  PlaceRoamingObject(Game.Campaign.Island, 12, Game.World.WizardPosition);
  PlaceRoamingObject(Game.Campaign.Island, 28, Game.World.MagePosition);

  for I := 25 to 29 do
  begin
    CreatureDefinitions[I] := Game.Campaign.Mutants[I];
    J := CreatureDefinitions[I].Cost.Price shr 8;
    LoadCreatureArt(J);
    CopyRecord(0, 0, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
    StoreMutantFrames(I - 25, 0);
  end;

  for I := 0 to 4 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      LoadCreatureArt(Game.Campaign.Army[I].Species);
      CopyRecord(0, I, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
    end;

  Count := 0;
  for I := 5 to 60 do
    for J := 5 to 60 do
      if Game.Campaign.Map[Game.Campaign.Island, I, J] = 9 then
      begin
        Inc(Count);
        Positions[Count].X := I;
        Positions[Count].Y := J;
        Game.Campaign.Map[Game.Campaign.Island, I, J] := 0;
      end;

  while Count > 0 do
  begin
    repeat
      I := Random(65);
      J := Random(65)
    until Game.Campaign.Map[Game.Campaign.Island, I, J] = 0;
    Game.Campaign.Map[Game.Campaign.Island, I, J] := 9;
    Dec(Count);
  end;

  for J := 3 to 65 do
    for I := 3 to 65 do
      if Game.Campaign.Map[5, I, J] = 22 then
      begin
        Game.Runtime.SpiritStonePosition.X := I;
        Game.Runtime.SpiritStonePosition.Y := J;
        goto SpiritFound;
      end;

SpiritFound:
  for I := 0 to 7 do Game.Runtime.SpellTitles[I] := SpellColors[Game.Campaign.SpellColors[I]];
  if Game.Campaign.Flags.ShipOwned then ComposeTile(Game.Campaign.ShipBackground);
  RefreshRoamingArmyArt;
  Game.World.TimeStopAccumulated := Game.Campaign.ExtraDays;
  Game.Campaign.Flags.Heading := true;
  Game.Campaign.ShipHeading := 1;
end;
end.
