unit KBSaveUI;
{$G+,R-,S-,I+,A+}

interface

procedure SaveNamedGame;

implementation

uses KBSave, KBUI, KBGfx, Crt, KBState;

procedure SaveNamedGame;
var
  Length: byte;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 14, 256, 'Введите имя файла (8 символов):');
  Game.Runtime.DataFileName := '';
  Length := 0;

  repeat
    repeat
      Game.Runtime.LastScan := Ord(ReadKey)
    until Game.Runtime.LastScan <> 0;

    if Game.Runtime.LastScan = 8 then
    begin
      if Length > 0 then
      begin
        Dec(Length);
        DrawText(false, Length + 26, 272, ' ');

        if Length > 0 then Game.Runtime.DataFileName := Copy(Game.Runtime.DataFileName, 1, Length)
        else Game.Runtime.DataFileName := '';
      end;
    end
    else if Game.Runtime.LastScan > 47 then
    begin
      Game.Runtime.DataFileName := Concat(Game.Runtime.DataFileName, Chr(Game.Runtime.LastScan));
      Inc(Length);
      DrawText(false, 26, 272, Game.Runtime.DataFileName);
    end;
  until (Game.Runtime.LastScan = 13) or (Game.Runtime.LastScan = 27) or (Length = 8);

  if (Game.Runtime.LastScan = 27) or (Game.Runtime.DataFileName = '') then
  begin
  end
  else
  begin
    Game.Runtime.DataFileName := Game.Runtime.DataFileName + '.KB2';
    PrepareSave;
    WriteCampaign;
  end;
end;
end.
