program CurrentBench;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}
uses KBState, KBStart, KBSess, KBBattle;
begin
  InitializeRuntime;
  SetGraphicsMode(1);
  LoadTitle;
  LoadGameArtwork;
  Game.Runtime.SoundDisabled := true;
  Battle(@Game.Campaign.GuardianSpecies, @Game.Campaign.GuardianCounts, 0);
end.
