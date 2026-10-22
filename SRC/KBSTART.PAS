unit KBStart;
{$G+,R-,S-,I+,A+}

interface

procedure InitializeRuntime;
procedure LoadTitle;
procedure LoadGameArtwork;
procedure StartupMenu;

implementation

uses KBInit, KBLpt, KBGen, KBRandom, Dos, KBState, KBTables, KBFiles, KBGfx, KBInput, KBSave;

procedure InitializeRuntime;
begin
  InitializeLegacyState;
  InitializePrinter;
  RandomizeGame;
  Game.Runtime.FontPointer := @Game.Runtime.Font;
  Game.Runtime.DataFileName := 'KB2.DAT';
  Game.Runtime.FontFileName := 'KB2.FNT';
  Game.Runtime.MoneyFileName := 'MONEY.PIC';
  Game.Runtime.WorldMapRedraw := 0;
  Game.Runtime.TownPictureLoaded := true;
  Game.Runtime.WorkerRestockPhase := true;
  Game.Runtime.RegrowthPosition.X := 100;
  Game.Runtime.RegrowthCountdown := 0;
end;

procedure LoadTitle;
begin
  Game.Runtime.PicturePage := 32768;
  SetVideoPage(0);
  Game.Runtime.PictureFileName := 'TITL.PIC';
  LoadScreenPicture;
  Game.Runtime.PicturePage := 0;
  SetVideoPage(1);
  LoadScreenPicture;
  Game.Runtime.PicturePage := 32768;
  LoadResourceFile(Game.Runtime.FontPointer, Game.Runtime.FontFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[12], Game.Runtime.MoneyFileName);
end;

procedure LoadGameArtwork;
begin
  LoadResourceFile(Game.Runtime.PictureBanks[0], Game.Runtime.SubjectOneFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[1], Game.Runtime.SubjectTwoFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[2], Game.Runtime.BattlePictureFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[3], Game.Runtime.WaterPictureFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[4], Game.Runtime.IslandPictureFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[5], Game.Runtime.ChartPictureFileName);
  LoadResourceFile(Game.Runtime.PictureBanks[13], Game.Runtime.EnemyPictureFileName);
  CopyRecord(14, 0, 2880, Game.Runtime.PictureBanks[0], Game.Runtime.PictureBanks[14]);
  Game.Runtime.CalmArmyPicture := Game.Runtime.PictureBanks[13];
  asm
    lea bx, Game.Runtime.CalmArmyPicture
    mov ax, [bx]
    add ax, 2880
    mov [bx], ax
  end;
end;

procedure StartupMenu;
label
  MenuAgain, Finished;

var
  MenuChoice, I: byte;
  SaveFileSearch: SearchRec;
  SaveFileNames: array[0..9] of string[12];
  SaveFileCount: byte;

procedure ResetMenuPage;
begin
  SetVideoPage(0);
  Game.Runtime.PictureFileName := 'TOWN.PIC';
  LoadScreenPicture;
  Game.Runtime.PicturePage := 0;
end;

procedure DrawStartupMenu;
var
  I: byte;

begin
  ClearRectangle(464, 26, 592, 154);
  for I := 1 to 2 do DrawText(false, 60, I * 10 + 70, MainMenu[I]);
  DrawText(false, 2, 8, 'Выбеpите ваpиант загpузки игpы и нажмите "Enter"');
end;

procedure NewGame;
var
  I: byte;

begin
  MenuChoice := 0;
  DrawText(false, 2, 8, 'Выбеpите уpовень сложности игpы                 ');

  for I := 1 to 3 do DrawText(false, 60, I * 10 + 60, Difficulties[I]);
  repeat
    DrawText(true, 60, MenuChoice * 10 + 60, Difficulties[MenuChoice]);
    Game.Runtime.LastScan := ReadScanCode;
    DrawText(false, 60, MenuChoice * 10 + 60, Difficulties[MenuChoice]);

    case Game.Runtime.LastScan of
      72: if MenuChoice > 0 then Dec(MenuChoice)
      else MenuChoice := 3;
      80: if MenuChoice < 3 then Inc(MenuChoice)
      else MenuChoice := 0;
    end;
  until Game.Runtime.LastScan = 28;
  ResetMenuPage;
  DrawText(false, 2, 8, 'Подождите пожалуйста, подготавливается новая игpа.');
  PrepareCampaign(MenuChoice);
  GenerateWorld(MenuChoice);
  PlaceInitialHero(MenuChoice);
  PrepareSave;
  WriteCampaign;
end;

procedure EnumerateFiles;
label
  Finished;

var
  UnknownLocal: byte;

begin
  FindFirst('*.KB2', 63, SaveFileSearch);
  if DosError = 2 then
  begin
    SaveFileCount := 100;
    goto Finished
  end
  else
  begin
  SaveFileNames[0] := SaveFileSearch.Name;
  SaveFileCount := 0;

  repeat
    Inc(SaveFileCount);
    FindNext(SaveFileSearch);
    SaveFileNames[SaveFileCount] := SaveFileSearch.Name;
  until (SaveFileCount = 9) or (DosError = 18);

  if DosError = 18 then Dec(SaveFileCount);
  end;

Finished:
end;

procedure TrimFileNames;
var
  J: byte;

begin
  for J := 0 to SaveFileCount do SaveFileNames[J] := Copy(SaveFileNames[J], 1, Pos('.', SaveFileNames[J]) - 1);
end;

procedure DrawFileNames;
var
  J: byte;

begin
  for J := 0 to 2 do DrawText(false, 60, J * 10 + 70, '            ');
  for J := 0 to SaveFileCount do DrawText(false, 62, J * 10 + 30, SaveFileNames[J]);
end;

function LoadNamedGame: boolean;
label
  Finished;

begin
  DrawText(false, 2, 8, 'Выбеpите имя файла и нажмите  "Enter"           ');
  EnumerateFiles;

  if SaveFileCount < 100 then TrimFileNames
  else
  begin
    LoadNamedGame := false;
    goto Finished
  end;

  DrawFileNames;
  MenuChoice := 0;
  LoadNamedGame := true;

  repeat
    DrawText(true, 62, MenuChoice * 10 + 30, SaveFileNames[MenuChoice]);
    Game.Runtime.LastScan := ReadScanCode;
    DrawText(false, 62, MenuChoice * 10 + 30, SaveFileNames[MenuChoice]);

    case Game.Runtime.LastScan of
      72: if MenuChoice > 0 then Dec(MenuChoice)
      else MenuChoice := SaveFileCount;
      80: if MenuChoice < SaveFileCount then Inc(MenuChoice)
      else MenuChoice := 0;
    end;
  until Game.Runtime.LastScan = 28;
  ResetMenuPage;
  Game.Runtime.DataFileName := SaveFileNames[MenuChoice] + '.KB2';
  ReadCampaign;
  Game.Campaign.Flags.Heading := true;
  Game.Campaign.ShipHeading := 1;
  Game.Runtime.DataFileName := 'KB2.DAT';
  WriteCampaign;
Finished:
end;

begin
  MenuChoice := 0;
  for I := 0 to 9 do SaveFileNames[I] := '';
MenuAgain:
  DrawStartupMenu;

  repeat
    DrawText(true, 60, MenuChoice * 10 + 70, MainMenu[MenuChoice]);
    Game.Runtime.LastScan := ReadScanCode;
    DrawText(false, 60, MenuChoice * 10 + 70, MainMenu[MenuChoice]);

    case Game.Runtime.LastScan of
      72: if MenuChoice > 0 then Dec(MenuChoice)
      else MenuChoice := 2;
      80: if MenuChoice < 2 then Inc(MenuChoice)
      else MenuChoice := 0;
    end;
  until Game.Runtime.LastScan = 28;

  case MenuChoice of
    0: NewGame;
    1: begin
      ResetMenuPage;
      ReadCampaign
    end;

    2: if LoadNamedGame then goto Finished
    else goto MenuAgain;
  end;

Finished:
end;

end.
