unit KBCampgn;
{$G+,R-,S-,I+,A+}

interface

uses KBTypes, KBState;

procedure SetGraphicsMode(GameMode: byte);

procedure RestoreControls;

procedure VictoryReport(Slot, Kind: byte);

procedure DefeatReport;

procedure CleanupGame;

procedure GameOver;

procedure CastTimeStop;

procedure CastleTeleport;

procedure TownTeleport;

procedure SummonArmy;

procedure GiftScroll;

procedure AdventureMagic;

procedure ArmyOverview;

procedure CastleVisit;

implementation

uses KBFiles, KBArt, KBUI, KBInput, KBGfx, KBTables, KBBattle, KBAdvent, KBSound,
  KBWorld, Crt;

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

  if Game.ContractIsland >= 6 then
  begin
    ClearPicturePlanes(1822, 6);
    DrawPicturePlanes(1822, 17, 9);
  end
  else DrawPictureTile(1822, 17);

  if Game.SiegeEngineOwned then DrawPictureTile(6622, 16)
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
  DrawText(false, 30, 240, 'è é Å Ö Ñ Ä !');
  DrawText(false, 2, 264, 'B Ì‚Æ© °®‚¢• ÇÎ ß†p†°Æ‚†´®:');
  DrawText(false, 2, 274, 'B†Ë †¢‚Æp®‚•‚ ØÆ¢Î·®´·Ô ≠†:');

  if Kind = 2 then Game.AuthorityChange := Random(Game.BattleValue div 500) + Game.BattleValue div 1000
  else Game.AuthorityChange := Random(Game.BattleValue div 500);
  Str(Game.BattleValue, Game.TextBuffer);
  Game.TextBuffer := Game.TextBuffer + '$';
  DrawText(false, 30, 264, Game.TextBuffer);
  Str(Game.AuthorityChange, Game.TextBuffer);
  DrawText(false, 30, 274, Game.TextBuffer);
  Inc(Game.Gold, Game.BattleValue);
  Inc(Game.Leadership, Game.AuthorityChange);

  if Kind = 5 then
  begin
    Game.Map[Game.Island, Game.WanderingArmies[Game.Island, Slot].X, Game.WanderingArmies[Game.Island, Slot].Y] := 0;
    Game.WanderingArmies[Game.Island, Slot].X := 255;
  end;

  PlayCue(0);
  Game.LastScan := ReadScanCode;
end;

procedure DefeatReport;
var
  UnknownLocal: word;

begin
  Game.ArmyAvailable := false;
  DrawDialog(8, 230, 584, 320);
  DrawText(false, 26, 240, 'è é ê Ä Ü Ö ç à Ö !');
  DrawText(false, 2, 264, 'ÇÎ ØpÆ®£p†´® ¢ Ì‚Æ© °®‚¢•. à ØpÆ‚®¢≠®™ ß†£≠†´ Ç†· ≠•®ß¢•·‚≠Æ ™„§†.');
  DrawText(false, 2, 274, 'B†Ë †¢‚Æp®‚•‚ „¨•≠ÏË®´·Ô ≠†:');
  EncounterLanding;

  if Game.ShipOwned then AbandonShip;
  RandomHeroLanding;
  Game.AuthorityChange := Random(Game.BattleValue div 400);
  Game.EnemyGrace := 40;
  Str(Game.AuthorityChange, Game.TextBuffer);
  DrawText(false, 31, 274, Game.TextBuffer);
  CopyRecord(0, 5, 2880, Game.CalmArmyPicture, Game.PictureBanks[0]);

  if Game.AuthorityChange < Game.Leadership then Game.Leadership := Game.Leadership - Game.AuthorityChange
  else Game.Leadership := 10;
  Game.SiegeEngineOwned := false;
  PlayCue(7);
  Game.LastScan := ReadScanCode;
end;

procedure CleanupGame;
begin
  SetGraphicsMode(0);
  FreeMem(Game.PictureBanks[11], 8640);
  FreeMem(Game.PictureBanks[10], 43200);
  FreeMem(Game.PictureBanks[12], 11520);
  FreeMem(Game.PictureBanks[14], 2880);
  FreeMem(Game.PictureBanks[13], 5760);
  FreeMem(Game.PictureBanks[0], 46800);
  FreeMem(Game.PictureBanks[1], 46800);
  FreeMem(Game.PictureBanks[2], 46800);
  FreeMem(Game.PictureBanks[3], 46800);
  FreeMem(Game.PictureBanks[4], 46800);
  FreeMem(Game.PictureBanks[5], 46800);
end;

procedure GameOver;
begin
  Game.PicturePage := 32768;
  Game.PictureFileName := 'YOULOSE.PIC';
  LoadScreenPicture;
  SetVideoPage(1);
  Game.LastScan := ReadScanCode;
  SetVideoPage(0);
  CleanupGame;
  Halt;
end;

procedure CastTimeStop;
var
  Days: word;

begin
  if Game.TimeStopAccumulated < 500 then
  begin
    Days := Game.MagicPower * 10 + 1;

    if Game.TimeStopAccumulated + Days > 500 then
    begin
      Game.ExtraDays := Game.ExtraDays + 500 - Game.TimeStopAccumulated;
      Game.TimeStopAccumulated := 500;
    end
    else
    begin
      Inc(Game.ExtraDays, Days);
      Inc(Game.TimeStopAccumulated, Days);
    end;

    DrawText(false, 64, 8, 'ÑHà:      ');
    Game.MagicCastSucceeded := true;
    Str(Game.ExtraDays, Game.TextBuffer);
    DrawText(false, 68, 8, Game.TextBuffer);
    Dec(Game.Scrolls[0]);
  end
  else ShowNotice(22);
end;

procedure CastleTeleport;
label
  Finished;

var
  Count, Cursor: byte;

begin
  Count := 0;
  Cursor := 0;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(12);

  while (Game.VisitedCastles[Count].Island > 0) and (Count < 26) do
  begin
    DrawText(false, Count div 9 * 11 + 2, Count mod 9 * 8 + 240,
      CastleNames[Game.Castles[Game.VisitedCastles[Count].Island, Game.VisitedCastles[Count].Slot].Name]);
    Inc(Count);
  end;

  if Count = 0 then
  begin
    ShowNotice(2);
    goto Finished
  end
  else Dec(Count);
    repeat
      DrawText(true, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        CastleNames[Game.Castles[Game.VisitedCastles[Cursor].Island, Game.VisitedCastles[Cursor].Slot].Name]);
      Game.LastScan := ReadScanCode;
      DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        CastleNames[Game.Castles[Game.VisitedCastles[Cursor].Island, Game.VisitedCastles[Cursor].Slot].Name]);

      case Game.LastScan of
        72: if Cursor > 0 then Dec(Cursor);
        75: if Cursor > 8 then Dec(Cursor, 9);
        77: if Cursor + 8 < Count then Inc(Cursor, 9);
        80: if Cursor < Count then Inc(Cursor);
        28: begin
          Dec(Game.Scrolls[2]);
          Game.MagicCastSucceeded := true;
          EnterIsland(Game.VisitedCastles[Cursor].Island);
          Game.Hero.X := Game.Castles[Game.VisitedCastles[Cursor].Island, Game.VisitedCastles[Cursor].Slot].X;
          Game.Hero.Y := Game.Castles[Game.VisitedCastles[Cursor].Island, Game.VisitedCastles[Cursor].Slot].Y + 1;
        end;
      end;
    until (Game.LastScan = 1) or (Game.LastScan = 28);
Finished:
  HeaderPrompt(0);
end;

procedure TownTeleport;
label
  Finished, LandingFound;

var
  DX, DY: shortint;
  Count, Cursor: byte;

begin
  Count := 0;
  Cursor := 0;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(13);

  while (Game.VisitedTowns[Count].Island > 0) and (Count < 26) do
  begin
    DrawText(false, Count div 9 * 11 + 2, Count mod 9 * 8 + 240,
      TownNames[Game.Towns[Game.VisitedTowns[Count].Island, Game.VisitedTowns[Count].Slot].Name]);
    Inc(Count);
  end;

  if Count = 0 then
  begin
    ShowNotice(4);
    goto Finished
  end
  else Dec(Count);
    repeat
      DrawText(true, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        TownNames[Game.Towns[Game.VisitedTowns[Cursor].Island, Game.VisitedTowns[Cursor].Slot].Name]);
      Game.LastScan := ReadScanCode;
      DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        TownNames[Game.Towns[Game.VisitedTowns[Cursor].Island, Game.VisitedTowns[Cursor].Slot].Name]);

      case Game.LastScan of
        72: if Cursor > 0 then Dec(Cursor);
        75: if Cursor > 8 then Dec(Cursor, 9);
        77: if Cursor + 8 < Count then Inc(Cursor, 9);
        80: if Cursor < Count then Inc(Cursor);
        28: begin
          Dec(Game.Scrolls[3]);
          Game.MagicCastSucceeded := true;
          EnterIsland(Game.VisitedTowns[Cursor].Island);
          Game.GenerationX := Game.Towns[Game.VisitedTowns[Cursor].Island, Game.VisitedTowns[Cursor].Slot].X;
          Game.GenerationY := Game.Towns[Game.VisitedTowns[Cursor].Island, Game.VisitedTowns[Cursor].Slot].Y;

          for DX := -1 to 1 do
            for DY := -1 to 1 do
              if Game.Map[Game.Island, Game.GenerationX + DX, Game.GenerationY + DY] = 0 then goto LandingFound;
LandingFound:
          Game.Hero.X := Game.GenerationX + DX;
          Game.Hero.Y := Game.GenerationY + DY;
        end;
      end;
    until (Game.LastScan = 1) or (Game.LastScan = 28);
Finished:
  HeaderPrompt(0);
end;

procedure SummonArmy;
label
  Finished;

var
  Cursor, Slot: shortint;
  UnknownLocal, Quantity: word;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(14);
  DrawText(false, 50, 240, 'äÆ´®Á•·‚¢Æ');

  for Cursor := 0 to SummoningSpeciesLimits[Game.Island] do
  begin
    DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);
  end;

  Cursor := 0;
  repeat
    DrawText(true, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);

    if Game.MapParts < 4 then Quantity := Game.MagicPower * 30 div CreatureDefinitions[Cursor].Defense
    else Quantity := Game.MagicPower * 70 div CreatureDefinitions[Cursor].Defense;
    Str(Quantity, Game.TextBuffer);
    DrawText(false, 53, 248, Game.TextBuffer);
    Game.LastScan := ReadScanCode;
    DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);
    DrawText(false, 53, 248, '    ');

    case Game.LastScan of
      72: if Cursor > 0 then Dec(Cursor);
      75: if Cursor > 8 then Dec(Cursor, 9);
      77: if Cursor + 8 < SummoningSpeciesLimits[Game.Island] then Inc(Cursor, 9);
      80: if Cursor < SummoningSpeciesLimits[Game.Island] then Inc(Cursor);
      28: begin
        if Quantity = 0 then goto Finished;
        Dec(Game.Scrolls[4]);
        Slot := -1;
        Game.MagicCastSucceeded := true;

        repeat
          Inc(Slot)
        until (Slot > 9) or (Game.Army[Slot].Species = Cursor);

        if Slot <= 9 then Inc(Game.Army[Slot].Count, Quantity)
        else
        begin
          Slot := -1;

          repeat
            Inc(Slot)
          until (Game.Army[Slot].Species = 100) or (Slot > 9);

          if Slot > 9 then
          begin
            ShowNotice(6);
            goto Finished
          end;

          Game.Army[Slot].Count := Quantity;
          Game.Army[Slot].Species := Cursor;
          if Slot < 5 then
          begin
            LoadCreatureArt(Cursor);
            CopyRecord(0, Slot, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
          end;
        end;
      end;
    end;
  until (Game.LastScan = 1) or (Game.LastScan = 28);
Finished:
  HeaderPrompt(0);
end;

procedure GiftScroll;
var
  Cursor: byte;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(15);

  for Cursor := 0 to 13 do
  begin
    DrawText(false, Cursor div 9 * 26 + 2, Cursor mod 9 * 8 + 240, ScrollNames[Cursor]);
  end;

  Cursor := 0;
  repeat
    DrawText(true, Cursor div 9 * 26 + 2, Cursor mod 9 * 8 + 240, ScrollNames[Cursor]);
    Game.LastScan := ReadScanCode;
    DrawText(false, Cursor div 9 * 26 + 2, Cursor mod 9 * 8 + 240, ScrollNames[Cursor]);

    case Game.LastScan of
      72: if Cursor > 0 then Dec(Cursor);
      75: if Cursor > 8 then Dec(Cursor, 9);
      77: if Cursor + 8 < 13 then Inc(Cursor, 9);
      80: if Cursor < 13 then Inc(Cursor);
      28: begin
        Dec(Game.Scrolls[6]);
        Inc(Game.Scrolls[Cursor]);
        Game.MagicCastSucceeded := true;
      end;
    end;
  until (Game.LastScan = 1) or (Game.LastScan = 28);
  HeaderPrompt(0);
end;

procedure AdventureMagic;
label
  Finished, RestoreHeader;

var
  I, X, Y, OldIsland, Total: byte;

procedure AnimateSpell;
begin
  DrawPictureTile(16161, Game.Map[OldIsland, Game.Hero.X - 2, Game.Hero.Y + 1]);
  DrawPictureTile(16173, Game.Map[OldIsland, Game.Hero.X - 1, Game.Hero.Y + 1]);
  DrawPictureTile(16185, Game.Map[OldIsland, Game.Hero.X, Game.Hero.Y + 1]);
  DrawPictureTile(16197, Game.Map[OldIsland, Game.Hero.X + 1, Game.Hero.Y + 1]);
  DrawPictureTile(16209, Game.Map[OldIsland, Game.Hero.X + 2, Game.Hero.Y + 1]);
  DrawPictureTile(20961, Game.Map[OldIsland, Game.Hero.X - 2, Game.Hero.Y + 2]);
  DrawPictureTile(20973, Game.Map[OldIsland, Game.Hero.X - 1, Game.Hero.Y + 2]);
  DrawPictureTile(20985, Game.Map[OldIsland, Game.Hero.X, Game.Hero.Y + 2]);
  DrawPictureTile(20997, Game.Map[OldIsland, Game.Hero.X + 1, Game.Hero.Y + 2]);
  DrawPictureTile(21009, Game.Map[OldIsland, Game.Hero.X + 2, Game.Hero.Y + 2]);
  DrawMaskedTile(11385, 6, 1);
  Delay(50);
  DrawMaskedTile(11385, 6, 2);
  Delay(50);
  DrawMaskedTile(11385, 6, 4);
  Delay(50);
  DrawMaskedTile(11385, 6, 8);
  Delay(50);
end;

begin
  if Game.MagicPower = 0 then
  begin
    ShowNotice(5);
    goto Finished
  end;

  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(2);
  OldIsland := Game.Island;
  Game.MagicCastSucceeded := false;
  Total := 0;
  DrawText(false, 8, 240, 'èéãäéÇéÑÖñ    -     CíêÄççàä');
  DrawText(false, 6, 256, 'íÖãÖèéêí       (1) éëíÄçéÇäÄ ÇêÖåÖçà');
  DrawText(false, 6, 264, 'êÄáåçéÜÖçàÖ    (2) CMà-à-àêçé!');
  DrawText(false, 6, 272, 'òÄêéÇÄü åéãçàü (3) èÖêÖïéÑ ä áÄåäì');
  DrawText(false, 6, 280, 'åéêéá          (4) èÖêÖïéÑ ä ÉéêéÑì');
  DrawText(false, 6, 288, 'ÑìÅàçäÄ        (5) ÑÄíú Äêåàû');
  DrawText(false, 6, 296, 'ÇéëäêÖòÖçàÖ    (6) äÇÄáà ÄÇíéêàíÖí');
  DrawText(false, 6, 304, 'àçîÖäñàü       (7) ÑÄíú ÇéãòÖÅëíÇé');
  DrawText(true, 50, 240, 'é°È••');
  DrawText(true, 48, 248, '™Æ´®Á•·‚¢Æ');

  for I := 0 to 13 do
  begin
    Str(Game.Scrolls[I]: 2, Game.TextBuffer);
    Inc(Total, Game.Scrolls[I]);

    if I < 7 then
    begin
      X := 43;
      Y := I * 8
    end
    else
    begin
      X := 2;
      Y := (I - 7) * 8
    end;

    DrawText(false, X, Y + 256, Game.TextBuffer);
  end;

  Str(Total, Game.TextBuffer);
  DrawText(true, 52, 264, Game.TextBuffer);
  repeat
    Game.LastScan := ReadScanCode
  until (Game.LastScan = 1) or (Game.LastScan in [2..8]);

  if Game.LastScan = 1 then goto RestoreHeader;
  case Game.LastScan of
    2: if Game.Scrolls[0] > 0 then CastTimeStop
    else ShowNotice(0);
    3: if Game.Scrolls[1] > 0 then
    begin
      if Game.MagicPower > 5 then Game.EnemyGrace := Game.MagicPower
      else Game.EnemyGrace := Game.MagicPower * 3;
      Game.MagicCastSucceeded := true;
      Dec(Game.Scrolls[1]);
      CopyRecord(0, 5, 2880, Game.CalmArmyPicture, Game.PictureBanks[0]);
    end
    else ShowNotice(0);
    4: if Game.Scrolls[2] > 0 then CastleTeleport
    else ShowNotice(0);
    5: if Game.Scrolls[3] > 0 then TownTeleport
    else ShowNotice(0);
    6: if Game.Scrolls[4] > 0 then SummonArmy
    else ShowNotice(0);
    7: if Game.Scrolls[5] > 0 then
    begin
      Game.LeadershipBonus := Game.LeadershipBonus + Game.MagicPower * 50;
      Game.MagicCastSucceeded := true;
      Dec(Game.Scrolls[5]);
    end
    else ShowNotice(0);
    8: if Game.Scrolls[6] > 0 then GiftScroll
    else ShowNotice(0);
  end;

  if Game.MagicCastSucceeded then AnimateSpell;
RestoreHeader:
  HeaderPrompt(0);
Finished:
end;

{$I ARMY.INC}
{$I CASTLE.INC}

begin
end.
