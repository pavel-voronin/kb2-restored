unit KBArt;
{$G+,R-,S-,I+,A+}

interface

procedure LoadCreatureArt(Creature: byte);

implementation

uses KBState, KBFiles;

const
  ArmyPrefix = 'ARMY';
  PictureSuffix = '.PIC';
procedure LoadCreatureArt(Creature: byte);
var
  Bank, Frame: byte;

begin
  Bank := Creature div 5;
  Frame := Creature mod 5;
  Game.CachedCreatureId := Creature;
  Str(Bank, Game.TextBuffer);
  Game.TextBuffer := ArmyPrefix + Game.TextBuffer + PictureSuffix;
  LoadCreatureFrames(Frame, Game.PictureBanks[11], Game.TextBuffer);
end;


end.
