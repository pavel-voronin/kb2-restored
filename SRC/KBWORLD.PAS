unit KBWorld;
{$G+,R-,S-,I+,A+}

interface

uses KBTypes;

procedure ForgetDiscovery;

procedure PlaceRoamingObject(Island, Code: byte; var P: TPosition);

procedure EnterIsland(Island: byte);

procedure RelocateArmy(Island, Slot: byte);

implementation

uses KBState;

procedure ForgetDiscovery;
begin
  FillChar(Game.Campaign.Flags.Discovery, SizeOf(Game.Campaign.Flags.Discovery), 0);
  FillChar(Game.Campaign.VisitedCastles, SizeOf(Game.Campaign.VisitedCastles), 0);
  FillChar(Game.Campaign.VisitedTowns, SizeOf(Game.Campaign.VisitedTowns), 0);
end;

procedure PlaceRoamingObject(Island, Code: byte; var P: TPosition);
begin
  repeat
    P.X := Random(65);
    P.Y := Random(65);
  until Game.Campaign.Map[Island, P.X, P.Y] = 0;
  Game.Campaign.Map[Island, P.X, P.Y] := Code;
end;

procedure EnterIsland(Island: byte);
begin
  Game.Campaign.Map[Game.Campaign.Island, Game.World.WizardPosition.X, Game.World.WizardPosition.Y] := 0;
  Game.Campaign.Map[Game.Campaign.Island, Game.World.MagePosition.X, Game.World.MagePosition.Y] := 0;

  if Island = 0 then Island := Random(5) + 1;
  if Island > 5 then Island := 5;
  PlaceRoamingObject(Island, 12, Game.World.WizardPosition);
  PlaceRoamingObject(Island, 28, Game.World.MagePosition);
  Game.Campaign.Island := Island;
end;

procedure RelocateArmy(Island, Slot: byte);
begin
  repeat
    Game.World.GenerationX := Random(65);
    Game.World.GenerationY := Random(65);
  until Game.Campaign.Map[Island, Game.World.GenerationX, Game.World.GenerationY] = 0;
  Game.Campaign.WanderingArmies[Island, Slot].X := Game.World.GenerationX;
  Game.Campaign.WanderingArmies[Island, Slot].Y := Game.World.GenerationY;
  Game.Campaign.Map[Island, Game.World.GenerationX, Game.World.GenerationY] := 5;
end;

end.
