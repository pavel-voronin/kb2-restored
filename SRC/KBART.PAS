unit KBArt;
{$G+,R-,S-,I+,A+}

interface

procedure LoadCreatureArt(Creature: byte);

procedure AllocateArtwork;
procedure ReleaseArtwork;

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
  Game.Runtime.CachedCreatureId := Creature;
  Str(Bank, Game.Runtime.TextBuffer);
  Game.Runtime.TextBuffer := ArmyPrefix + Game.Runtime.TextBuffer + PictureSuffix;
  LoadCreatureFrames(Frame, Game.Runtime.PictureBanks[11], Game.Runtime.TextBuffer);
end;

procedure AllocateArtwork;
begin
  GetMem(Game.Runtime.PictureBanks[11], 8640);
  GetMem(Game.Runtime.PictureBanks[10], 43200);
  GetMem(Game.Runtime.PictureBanks[12], 11520);
  GetMem(Game.Runtime.PictureBanks[14], 2880);
  GetMem(Game.Runtime.PictureBanks[0], 46800);
  GetMem(Game.Runtime.PictureBanks[1], 46800);
  GetMem(Game.Runtime.PictureBanks[2], 46800);
  GetMem(Game.Runtime.PictureBanks[3], 46800);
  GetMem(Game.Runtime.PictureBanks[4], 46800);
  GetMem(Game.Runtime.PictureBanks[5], 46800);
  GetMem(Game.Runtime.PictureBanks[13], 5760);
  asm
    mov ax, ds
    mov es, ax
    lea di, Game.Runtime.PictureBanks
    add di, 24
    lea si, Game.Runtime.PictureBanks[44]
    movsw
    movsw
    lea si, Game.Runtime.PictureBanks[40]
    movsw
    movsw
    lea si, Game.Runtime.PictureBanks[48]
    movsw
    movsw
  end;
end;

procedure ReleaseArtwork;
begin
  FreeMem(Game.Runtime.PictureBanks[11], 8640);
  FreeMem(Game.Runtime.PictureBanks[10], 43200);
  FreeMem(Game.Runtime.PictureBanks[12], 11520);
  FreeMem(Game.Runtime.PictureBanks[14], 2880);
  FreeMem(Game.Runtime.PictureBanks[13], 5760);
  FreeMem(Game.Runtime.PictureBanks[0], 46800);
  FreeMem(Game.Runtime.PictureBanks[1], 46800);
  FreeMem(Game.Runtime.PictureBanks[2], 46800);
  FreeMem(Game.Runtime.PictureBanks[3], 46800);
  FreeMem(Game.Runtime.PictureBanks[4], 46800);
  FreeMem(Game.Runtime.PictureBanks[5], 46800);
end;

end.
