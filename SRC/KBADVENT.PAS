unit KBAdvent;
{$G+,R-,S-,I+,A+}

interface

uses KBTypes;

function CountRitualSpells: byte;

procedure PlaceHiddenSpell;

procedure RandomHeroLanding;

procedure AbandonShip;

procedure TransmuteDwellings(Island: byte);

procedure RefreshRoamingArmyArt;

procedure RefreshDwellings;

procedure MoveRoamer(Island, Tile: byte; var Position: TPosition);

procedure EncounterLanding;

implementation

uses KBTown, KBFiles, KBGfx, KBTables, KBWorld, KBSound, Crt, KBState;

function CountRitualSpells: byte;
var
  I, Count: byte;

begin
  Count := 0;
  for I := 0 to 7 do if Game.Campaign.Flags.SpellAvailable[I] then Inc(Count);
  CountRitualSpells := Count;
end;

procedure PlaceHiddenSpell;
begin
  if CountRitualSpells < 8 then
  begin
    Game.Campaign.HiddenSpellIsland := Random(49) div 10 + 1;

    repeat
      Game.Campaign.HiddenSpellPosition.X := Random(65);
      Game.Campaign.HiddenSpellPosition.Y := Random(65);
    until (Game.Campaign.Map[Game.Campaign.HiddenSpellIsland, Game.Campaign.HiddenSpellPosition.X,
    Game.Campaign.HiddenSpellPosition.Y] = 0)
      or (Game.Campaign.Map[Game.Campaign.HiddenSpellIsland, Game.Campaign.HiddenSpellPosition.X,
    Game.Campaign.HiddenSpellPosition.Y] > 64);
    repeat
      Game.Campaign.HiddenSpellEffect := Random(79) div 10
    until not Game.Campaign.Flags.SpellAvailable[Game.Campaign.HiddenSpellEffect];
  end;
end;

procedure RandomHeroLanding;
begin
  repeat
    Game.Campaign.Hero.X := Random(65);
    Game.Campaign.Hero.Y := Random(65);
  until Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y] = 0;
end;

procedure AbandonShip;
begin
  Game.Campaign.Map[Game.Campaign.ShipIsland, Game.Campaign.Ship.X, Game.Campaign.Ship.Y] :=
    Game.Campaign.ShipBackground;
  Game.Campaign.Flags.ShipOwned := false;
end;

procedure TransmuteDwellings(Island: byte);
var
  I, Species, Tier: byte;

begin
  case Game.Campaign.MagicPower of
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
    Game.Campaign.Dwellings[Island, I].Species := Species;
    Game.Campaign.Dwellings[Island, I].Count := WeeklyDwellingCapacities[Species];
  end;
end;

procedure RefreshRoamingArmyArt;
begin
  if Game.Campaign.EnemyGrace > 0 then CopyRecord(0, 5, 2880, Game.Runtime.CalmArmyPicture,
    Game.Runtime.PictureBanks[0])
  else CopyRecord(0, 5, 2880, Game.Runtime.PictureBanks[13], Game.Runtime.PictureBanks[0]);
end;

procedure RevealDwellingRange(Minimum, Maximum: byte);
var
  I, Island: byte;

begin
  for Island := 1 to 5 do
    for I := 0 to 7 do
      if (Game.Campaign.Dwellings[Island, I].Species > Minimum) and
        (Game.Campaign.Dwellings[Island, I].Species < Maximum) then
        if not (Game.Campaign.Map[Island, Game.Campaign.Dwellings[Island, I].X, Game.Campaign.Dwellings[Island,
    I].Y] in [1..3, 7, 18]) then
          Game.Campaign.Map[Island, Game.Campaign.Dwellings[Island, I].X, Game.Campaign.Dwellings[Island, I].Y] := 8;
end;

procedure RefreshDwellings;
begin
  if Game.Campaign.MagicPower > 10 then RevealDwellingRange(21, 25);
  if Game.Campaign.MagicPower > 4 then RevealDwellingRange(19, 22);

  if Game.Campaign.MagicPower > 2 then RevealDwellingRange(14, 20);
  if Game.Campaign.MagicPower > 0 then RevealDwellingRange(9, 15);
  if Game.Campaign.MagicPower in [1, 3, 5, 11] then PlayCue(5);
end;

procedure MoveRoamer(Island, Tile: byte; var Position: TPosition);
var
  X, Y: byte;

begin
  if PRoamingActor(@Position)^.Age > Game.Campaign.Difficulty then
  begin
    PRoamingActor(@Position)^.Age := 0;
    Game.Campaign.Map[Island, Position.X, Position.Y] := 0;
    PlaceRoamingObject(Island, Tile, Position);
  end
  else
  begin
    Inc(PRoamingActor(@Position)^.Age);
    X := Position.X;
    Y := Position.Y;
    Game.Runtime.RoamerDirection := Random(79) div 10;

    case Game.Runtime.RoamerDirection of
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

    if Game.Campaign.Map[Island, X, Y] = 0 then
    begin
      Game.Campaign.Map[Island, Position.X, Position.Y] := 0;
      Game.Campaign.Map[Island, X, Y] := Tile;
      Position.X := X;
      Position.Y := Y;
    end;
  end;
end;

procedure EncounterLanding;
begin
  if Game.Runtime.ShipAbandonBlocked then
  begin
    Game.Runtime.ShipAbandonBlocked := false;
    PlaceShip(Game.Campaign.Hero.X, Game.Campaign.Hero.Y);

    if Game.Campaign.Flags.Heading xor boolean(Game.Campaign.ShipHeading) then MirrorTileArt(6);
    Game.Campaign.ShipHeading := Ord(Game.Campaign.Flags.Heading);
  end;

  Game.Campaign.Hero.X := Game.World.GenerationX;
  Game.Campaign.Hero.Y := Game.World.GenerationY;
end;

end.
