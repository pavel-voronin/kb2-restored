unit KBRandom;
{$G+,R-,S-,A+}

interface

procedure RandomizeGame;
procedure UseRandomSeed(Seed: longint);
implementation

var
  FixedSeed: boolean;

procedure RandomizeGame;
begin
  if not FixedSeed then Randomize;
end;

procedure UseRandomSeed(Seed: longint);
begin
  FixedSeed := true;
  RandSeed := Seed;
end;

procedure UseClockSeed;
begin
  FixedSeed := false;
  Randomize;
end;

begin
  FixedSeed := false;
end.
