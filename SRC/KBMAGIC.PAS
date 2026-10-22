unit KBMagic;
{$G+,R-,S-,I+,A+}

interface

procedure AdventureMagic;

implementation

uses KBWorld, KBTables, KBUI, KBArt, KBGfx, KBInput, KBFiles, Crt, KBState;

procedure CastTimeStop;
var
  Days: word;

begin
  if Game.World.TimeStopAccumulated < 500 then
  begin
    Days := Game.Campaign.MagicPower * 10 + 1;

    if Game.World.TimeStopAccumulated + Days > 500 then
    begin
      Game.Campaign.ExtraDays := Game.Campaign.ExtraDays + 500 - Game.World.TimeStopAccumulated;
      Game.World.TimeStopAccumulated := 500;
    end
    else
    begin
      Inc(Game.Campaign.ExtraDays, Days);
      Inc(Game.World.TimeStopAccumulated, Days);
    end;

    DrawText(false, 64, 8, '„Hˆ:      ');
    Game.Runtime.MagicCastSucceeded := true;
    Str(Game.Campaign.ExtraDays, Game.Runtime.TextBuffer);
    DrawText(false, 68, 8, Game.Runtime.TextBuffer);
    Dec(Game.Campaign.Scrolls[0]);
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

  while (Game.Campaign.VisitedCastles[Count].Island > 0) and (Count < 26) do
  begin
    DrawText(false, Count div 9 * 11 + 2, Count mod 9 * 8 + 240,
      CastleNames[Game.Campaign.Castles[Game.Campaign.VisitedCastles[Count].Island,
    Game.Campaign.VisitedCastles[Count].Slot].Name]);
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
        CastleNames[Game.Campaign.Castles[Game.Campaign.VisitedCastles[Cursor].Island,
    Game.Campaign.VisitedCastles[Cursor].Slot].Name]);
      Game.Runtime.LastScan := ReadScanCode;
      DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        CastleNames[Game.Campaign.Castles[Game.Campaign.VisitedCastles[Cursor].Island,
    Game.Campaign.VisitedCastles[Cursor].Slot].Name]);

      case Game.Runtime.LastScan of
        72: if Cursor > 0 then Dec(Cursor);
        75: if Cursor > 8 then Dec(Cursor, 9);
        77: if Cursor + 8 < Count then Inc(Cursor, 9);
        80: if Cursor < Count then Inc(Cursor);
        28: begin
          Dec(Game.Campaign.Scrolls[2]);
          Game.Runtime.MagicCastSucceeded := true;
          EnterIsland(Game.Campaign.VisitedCastles[Cursor].Island);
          Game.Campaign.Hero.X := Game.Campaign.Castles[Game.Campaign.VisitedCastles[Cursor].Island,
    Game.Campaign.VisitedCastles[Cursor].Slot].X;
          Game.Campaign.Hero.Y := Game.Campaign.Castles[Game.Campaign.VisitedCastles[Cursor].Island,
    Game.Campaign.VisitedCastles[Cursor].Slot].Y + 1;
        end;
      end;
    until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan = 28);
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

  while (Game.Campaign.VisitedTowns[Count].Island > 0) and (Count < 26) do
  begin
    DrawText(false, Count div 9 * 11 + 2, Count mod 9 * 8 + 240,
      TownNames[Game.Campaign.Towns[Game.Campaign.VisitedTowns[Count].Island,
    Game.Campaign.VisitedTowns[Count].Slot].Name]);
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
        TownNames[Game.Campaign.Towns[Game.Campaign.VisitedTowns[Cursor].Island,
    Game.Campaign.VisitedTowns[Cursor].Slot].Name]);
      Game.Runtime.LastScan := ReadScanCode;
      DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240,
        TownNames[Game.Campaign.Towns[Game.Campaign.VisitedTowns[Cursor].Island,
    Game.Campaign.VisitedTowns[Cursor].Slot].Name]);

      case Game.Runtime.LastScan of
        72: if Cursor > 0 then Dec(Cursor);
        75: if Cursor > 8 then Dec(Cursor, 9);
        77: if Cursor + 8 < Count then Inc(Cursor, 9);
        80: if Cursor < Count then Inc(Cursor);
        28: begin
          Dec(Game.Campaign.Scrolls[3]);
          Game.Runtime.MagicCastSucceeded := true;
          EnterIsland(Game.Campaign.VisitedTowns[Cursor].Island);
          Game.World.GenerationX := Game.Campaign.Towns[Game.Campaign.VisitedTowns[Cursor].Island,
    Game.Campaign.VisitedTowns[Cursor].Slot].X;
          Game.World.GenerationY := Game.Campaign.Towns[Game.Campaign.VisitedTowns[Cursor].Island,
    Game.Campaign.VisitedTowns[Cursor].Slot].Y;

          for DX := -1 to 1 do
            for DY := -1 to 1 do
              if Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX + DX, Game.World.GenerationY + DY]
    = 0 then goto LandingFound;
LandingFound:
          Game.Campaign.Hero.X := Game.World.GenerationX + DX;
          Game.Campaign.Hero.Y := Game.World.GenerationY + DY;
        end;
      end;
    until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan = 28);
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
  DrawText(false, 50, 240, 'Š®«¨ç¥áâ¢®');

  for Cursor := 0 to SummoningSpeciesLimits[Game.Campaign.Island] do
  begin
    DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);
  end;

  Cursor := 0;
  repeat
    DrawText(true, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);

    if Game.Campaign.MapParts < 4 then Quantity := Game.Campaign.MagicPower * 30 div
    CreatureDefinitions[Cursor].Defense
    else Quantity := Game.Campaign.MagicPower * 70 div CreatureDefinitions[Cursor].Defense;
    Str(Quantity, Game.Runtime.TextBuffer);
    DrawText(false, 53, 248, Game.Runtime.TextBuffer);
    Game.Runtime.LastScan := ReadScanCode;
    DrawText(false, Cursor div 9 * 11 + 2, Cursor mod 9 * 8 + 240, CreatureDefinitions[Cursor].Name);
    DrawText(false, 53, 248, '    ');

    case Game.Runtime.LastScan of
      72: if Cursor > 0 then Dec(Cursor);
      75: if Cursor > 8 then Dec(Cursor, 9);
      77: if Cursor + 8 < SummoningSpeciesLimits[Game.Campaign.Island] then Inc(Cursor, 9);
      80: if Cursor < SummoningSpeciesLimits[Game.Campaign.Island] then Inc(Cursor);
      28: begin
        if Quantity = 0 then goto Finished;
        Dec(Game.Campaign.Scrolls[4]);
        Slot := -1;
        Game.Runtime.MagicCastSucceeded := true;

        repeat
          Inc(Slot)
        until (Slot > 9) or (Game.Campaign.Army[Slot].Species = Cursor);

        if Slot <= 9 then Inc(Game.Campaign.Army[Slot].Count, Quantity)
        else
        begin
          Slot := -1;

          repeat
            Inc(Slot)
          until (Game.Campaign.Army[Slot].Species = 100) or (Slot > 9);

          if Slot > 9 then
          begin
            ShowNotice(6);
            goto Finished
          end;

          Game.Campaign.Army[Slot].Count := Quantity;
          Game.Campaign.Army[Slot].Species := Cursor;
          if Slot < 5 then
          begin
            LoadCreatureArt(Cursor);
            CopyRecord(0, Slot, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
          end;
        end;
      end;
    end;
  until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan = 28);
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
    Game.Runtime.LastScan := ReadScanCode;
    DrawText(false, Cursor div 9 * 26 + 2, Cursor mod 9 * 8 + 240, ScrollNames[Cursor]);

    case Game.Runtime.LastScan of
      72: if Cursor > 0 then Dec(Cursor);
      75: if Cursor > 8 then Dec(Cursor, 9);
      77: if Cursor + 8 < 13 then Inc(Cursor, 9);
      80: if Cursor < 13 then Inc(Cursor);
      28: begin
        Dec(Game.Campaign.Scrolls[6]);
        Inc(Game.Campaign.Scrolls[Cursor]);
        Game.Runtime.MagicCastSucceeded := true;
      end;
    end;
  until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan = 28);
  HeaderPrompt(0);
end;

procedure AdventureMagic;
label
  Finished, RestoreHeader;

var
  I, X, Y, OldIsland, Total: byte;

procedure AnimateSpell;
begin
  DrawPictureTile(16161, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16173, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16185, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16197, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16209, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(20961, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20973, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20985, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20997, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(21009, Game.Campaign.Map[OldIsland, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y + 2]);
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
  if Game.Campaign.MagicPower = 0 then
  begin
    ShowNotice(5);
    goto Finished
  end;

  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(2);
  OldIsland := Game.Campaign.Island;
  Game.Runtime.MagicCastSucceeded := false;
  Total := 0;
  DrawText(false, 8, 240, 'Ž‹ŠŽ‚Ž„…–    -     C’€ˆŠ');
  DrawText(false, 6, 256, '’…‹…Ž’       (1) Ž‘’€Ž‚Š€ ‚…Œ…ˆ');
  DrawText(false, 6, 264, '€‡ŒŽ†…ˆ…    (2) CMˆ-ˆ-ˆŽ!');
  DrawText(false, 6, 272, '˜€Ž‚€Ÿ ŒŽ‹ˆŸ (3) ……•Ž„ Š ‡€ŒŠ“');
  DrawText(false, 6, 280, 'ŒŽŽ‡          (4) ……•Ž„ Š ƒŽŽ„“');
  DrawText(false, 6, 288, '„“ˆŠ€        (5) „€’œ €Œˆž');
  DrawText(false, 6, 296, '‚Ž‘Š…˜…ˆ…    (6) Š‚€‡ˆ €‚’Žˆ’…’');
  DrawText(false, 6, 304, 'ˆ”…Š–ˆŸ       (7) „€’œ ‚Ž‹˜…‘’‚Ž');
  DrawText(true, 50, 240, 'Ž¡é¥¥');
  DrawText(true, 48, 248, 'ª®«¨ç¥áâ¢®');

  for I := 0 to 13 do
  begin
    Str(Game.Campaign.Scrolls[I]: 2, Game.Runtime.TextBuffer);
    Inc(Total, Game.Campaign.Scrolls[I]);

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

    DrawText(false, X, Y + 256, Game.Runtime.TextBuffer);
  end;

  Str(Total, Game.Runtime.TextBuffer);
  DrawText(true, 52, 264, Game.Runtime.TextBuffer);
  repeat
    Game.Runtime.LastScan := ReadScanCode
  until (Game.Runtime.LastScan = 1) or (Game.Runtime.LastScan in [2..8]);

  if Game.Runtime.LastScan = 1 then goto RestoreHeader;
  case Game.Runtime.LastScan of
    2: if Game.Campaign.Scrolls[0] > 0 then CastTimeStop
    else ShowNotice(0);
    3: if Game.Campaign.Scrolls[1] > 0 then
    begin
      if Game.Campaign.MagicPower > 5 then Game.Campaign.EnemyGrace := Game.Campaign.MagicPower
      else Game.Campaign.EnemyGrace := Game.Campaign.MagicPower * 3;
      Game.Runtime.MagicCastSucceeded := true;
      Dec(Game.Campaign.Scrolls[1]);
      CopyRecord(0, 5, 2880, Game.Runtime.CalmArmyPicture, Game.Runtime.PictureBanks[0]);
    end
    else ShowNotice(0);
    4: if Game.Campaign.Scrolls[2] > 0 then CastleTeleport
    else ShowNotice(0);
    5: if Game.Campaign.Scrolls[3] > 0 then TownTeleport
    else ShowNotice(0);
    6: if Game.Campaign.Scrolls[4] > 0 then SummonArmy
    else ShowNotice(0);
    7: if Game.Campaign.Scrolls[5] > 0 then
    begin
      Game.Campaign.LeadershipBonus := Game.Campaign.LeadershipBonus + Game.Campaign.MagicPower * 50;
      Game.Runtime.MagicCastSucceeded := true;
      Dec(Game.Campaign.Scrolls[5]);
    end
    else ShowNotice(0);
    8: if Game.Campaign.Scrolls[6] > 0 then GiftScroll
    else ShowNotice(0);
  end;

  if Game.Runtime.MagicCastSucceeded then AnimateSpell;
RestoreHeader:
  HeaderPrompt(0);
Finished:
end;
end.
