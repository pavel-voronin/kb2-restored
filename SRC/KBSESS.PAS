unit KBSess;
{$G+,R-,S-,I+,A+}

interface

procedure SetGraphicsMode(GameMode: byte);

procedure RestoreControls;

procedure VictoryReport(Slot, Kind: byte);

procedure DefeatReport;

procedure CleanupGame;

procedure GameOver;

implementation

uses KBHud, KBFiles, KBArt, KBUI, KBInput, KBGfx, KBAdvent, KBSound, Crt, KBState;

procedure SetGraphicsMode(GameMode: byte);
begin
  if GameMode <> 0 then
    asm
      mov ax, 16;
      int 10h
    end
  else
    asm
      mov ax, 2;
      int 10h
    end;
end;

procedure RestoreControls;
begin
  DrawLine(491, 20, 491, 323, 15);
  DrawLine(492, 20, 492, 323, 15);
  DrawLine(488, 20, 488, 323, 7);
  DrawLine(489, 20, 489, 323, 7);
  DrawLine(490, 20, 490, 323, 7);
  DrawLine(493, 20, 493, 323, 7);
  DrawLine(494, 20, 494, 323, 7);
  DrawLine(495, 20, 495, 323, 7);

  if Game.Campaign.ContractIsland >= 6 then
  begin
    ClearPicturePlanes(1822, 6);
    DrawPicturePlanes(1822, 17, 9);
  end
  else DrawPictureTile(1822, 17);

  if Game.Campaign.Flags.SiegeEngineOwned then DrawPictureTile(6622, 16)
  else
  begin
    ClearPicturePlanes(6622, 7);
    DrawPicturePlanes(6622, 16, 8);
  end;

  HeaderPrompt(0);
  RefreshMagic;
  RefreshMapParts;
  RefreshGold;
  DrawTime;
end;

procedure VictoryReport(Slot, Kind: byte);
begin
  DrawDialog(8, 230, 584, 320);
  DrawText(false, 30, 240, 'П О Б Е Д А !');
  DrawText(false, 2, 264, 'B этой битве Вы заpаботали:');
  DrawText(false, 2, 274, 'Bаш автоpитет повысился на:');

  if Kind = 2 then Game.Runtime.AuthorityChange := Random(Game.Runtime.BattleValue div 500) +
    Game.Runtime.BattleValue div 1000
  else Game.Runtime.AuthorityChange := Random(Game.Runtime.BattleValue div 500);
  Str(Game.Runtime.BattleValue, Game.Runtime.TextBuffer);
  Game.Runtime.TextBuffer := Game.Runtime.TextBuffer + '$';
  DrawText(false, 30, 264, Game.Runtime.TextBuffer);
  Str(Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
  DrawText(false, 30, 274, Game.Runtime.TextBuffer);
  Inc(Game.Campaign.Gold, Game.Runtime.BattleValue);
  Inc(Game.Campaign.Leadership, Game.Runtime.AuthorityChange);

  if Kind = 5 then
  begin
    Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.WanderingArmies[Game.Campaign.Island, Slot].X,
    Game.Campaign.WanderingArmies[Game.Campaign.Island, Slot].Y] := 0;
    Game.Campaign.WanderingArmies[Game.Campaign.Island, Slot].X := 255;
  end;

  PlayCue(0);
  Game.Runtime.LastScan := ReadScanCode;
end;

procedure DefeatReport;
var
  UnknownLocal: word;

begin
  Game.Campaign.Flags.ArmyAvailable := false;
  DrawDialog(8, 230, 584, 320);
  DrawText(false, 26, 240, 'П О Р А Ж Е Н И Е !');
  DrawText(false, 2, 264, 'Вы пpоигpали в этой битве. И пpотивник загнал Вас неизвестно куда.');
  DrawText(false, 2, 274, 'Bаш автоpитет уменьшился на:');
  EncounterLanding;

  if Game.Campaign.Flags.ShipOwned then AbandonShip;
  RandomHeroLanding;
  Game.Runtime.AuthorityChange := Random(Game.Runtime.BattleValue div 400);
  Game.Campaign.EnemyGrace := 40;
  Str(Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
  DrawText(false, 31, 274, Game.Runtime.TextBuffer);
  CopyRecord(0, 5, 2880, Game.Runtime.CalmArmyPicture, Game.Runtime.PictureBanks[0]);

  if Game.Runtime.AuthorityChange < Game.Campaign.Leadership then Game.Campaign.Leadership :=
    Game.Campaign.Leadership - Game.Runtime.AuthorityChange
  else Game.Campaign.Leadership := 10;
  Game.Campaign.Flags.SiegeEngineOwned := false;
  PlayCue(7);
  Game.Runtime.LastScan := ReadScanCode;
end;

procedure CleanupGame;
begin
  SetGraphicsMode(0);
  ReleaseArtwork;
end;

procedure GameOver;
begin
  Game.Runtime.PicturePage := 32768;
  Game.Runtime.PictureFileName := 'YOULOSE.PIC';
  LoadScreenPicture;
  SetVideoPage(1);
  Game.Runtime.LastScan := ReadScanCode;
  SetVideoPage(0);
  CleanupGame;
  Halt;
end;

begin
end.
