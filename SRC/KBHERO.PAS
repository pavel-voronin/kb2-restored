unit KBHero;
{$G+,R-,S-,I+,A+}

interface

procedure DismissArmy;
procedure SearchRitualSpell;
procedure HeroStatus;
procedure RitualSpellReport;
procedure CastTornado;
procedure CargoReport;
procedure CurrentContract;
procedure SeaVoyage;

implementation

uses KBAdvent, KBRandom, KBSess, KBWorld, KBReport, KBVisit, KBTables, KBUI, KBGfx, KBInput, KBFiles, Crt, KBState;

procedure FirstSeriesEnding;
begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 23, 272, 'äéçÖñ èÖêÇéâ ëÖêàà');
  Game.Runtime.LastScan := ReadScanCode;
  CleanupGame;
  Halt;
end;

procedure DismissArmy;
label
  Finished;

var
  Rows: array[0..9] of byte;
  I, Row, Count: byte;
  Text: string[60];

begin
  Row := 0;
  Count := 0;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(2);
  DrawText(false, 17, 240, '- ìÇéãúçÖçàÖ Ç áÄèÄë -');

  for I := 0 to 9 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      Inc(Count);
      Rows[Row] := I;
      Str(Row, Game.Runtime.TextBuffer);
      Text := Game.Runtime.TextBuffer + ') ' + CreatureDefinitions[Game.Campaign.Army[I].Species].Name;
      Game.World.GenerationCount := Row mod 5 * 8 + 256;
      Game.World.GenerationLimit := Row div 5 * 20 + 3;
      DrawText(false, Lo(Game.World.GenerationLimit), Game.World.GenerationCount, Text);
      Inc(Row);
    end;

  if Count > 0 then
  begin
    repeat
      Game.Runtime.LastScan := Ord(ReadKey)
    until (Game.Runtime.LastScan in [48..57]) or (Game.Runtime.LastScan = 27);

    if Game.Runtime.LastScan = 27 then
    begin
      HeaderPrompt(0);
      goto Finished
    end;

    Val(Chr(Game.Runtime.LastScan), Row, Game.World.GenerationCount);
    if Game.Campaign.Army[Rows[Row]].Species < 100 then
    begin
      Game.Campaign.Army[Rows[Row]].Species := 100;

      if Count = 1 then Game.Campaign.Flags.ArmyAvailable := false;
    end;
  end
  else
  begin
    DrawText(false, 17, 264, 'Ä „¢Æ´Ï≠Ô‚Ï ≠•™Æ£Æ.');
    Game.Runtime.LastScan := ReadScanCode;
  end;

  HeaderPrompt(0);
Finished:
end;

procedure SearchRitualSpell;
label
  LandingFound;

var
  I, J: shortint;
  Species: byte;
  UnknownLocal: array[1..5] of byte;

begin
  if (Game.Campaign.Island = Game.Campaign.HiddenSpellIsland) and (Game.World.GenerationX =
    Game.Campaign.HiddenSpellPosition.X)
    and (Game.World.GenerationY = Game.Campaign.HiddenSpellPosition.Y) then
  begin
    Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX, Game.World.GenerationY] := 23;

    for I := -1 to 1 do
      for J := -1 to 1 do
        if Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX + I, Game.World.GenerationY + J] = 0 then
    goto LandingFound;
LandingFound:
    Game.Campaign.Hero.X := Game.World.GenerationX + I;
    Game.Campaign.Hero.Y := Game.World.GenerationY + J;
    RandomizeGame;

    for I := 0 to 4 do
    begin
      Species := Random(249) div 10;
      Game.Campaign.GuardianCounts[I] := Game.Campaign.Leadership div CreatureDefinitions[Species].Defense;

      if Game.Campaign.GuardianCounts[I] > 0 then Game.Campaign.GuardianSpecies[I] := Species
      else Game.Campaign.GuardianSpecies[I] := 100;
    end;
  end
  else ShowNotice(21);
end;

procedure HeroStatus;
var
  I: byte;
  Reloaded: boolean;
  Payroll, Cost: longint;

begin
  Game.Runtime.PicturePage := 32768;
  if Game.Runtime.TownPictureLoaded then
  begin
    Game.Runtime.PictureFileName := 'STATUS.PIC';
    LoadScreenPicture;
    Game.Runtime.TownPictureLoaded := false;
    Reloaded := true;
  end
  else Reloaded := false;
  SetVideoPage(1);
  HeaderPrompt(6);
  Payroll := 0;

  for I := 2 to 5 do
    if Game.Campaign.Relics[I].Owned then DrawPictureTile(HeroRelicPositions[I], Game.Campaign.Relics[I].Artwork);
  for I := 0 to 9 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      Cost := CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price;
      Cost := Cost * Game.Campaign.Army[I].Count div 20;
      Payroll := Payroll + Cost;
    end;

  Str(Game.Campaign.Leadership + Game.Campaign.LeadershipBonus: 5, Game.Runtime.TextBuffer);
  DrawText(false, 67, 30, Game.Runtime.TextBuffer);
  Str(Game.Campaign.Gold: 8, Game.Runtime.TextBuffer);
  DrawText(false, 64, 50, Game.Runtime.TextBuffer);
  Str(Game.Campaign.Income: 6, Game.Runtime.TextBuffer);
  DrawText(false, 66, 60, Game.Runtime.TextBuffer);
  Str(Payroll: 6, Game.Runtime.TextBuffer);
  DrawText(false, 66, 70, Game.Runtime.TextBuffer);
  Str(Game.Campaign.MagicPower: 3, Game.Runtime.TextBuffer);
  DrawText(false, 69, 90, Game.Runtime.TextBuffer);
  Str(Game.Campaign.ScrollCapacity: 3, Game.Runtime.TextBuffer);
  DrawText(false, 69, 100, Game.Runtime.TextBuffer);
  Str(Game.Campaign.TornadoCharges: 3, Game.Runtime.TextBuffer);
  DrawText(false, 69, 120, Game.Runtime.TextBuffer);
  Str(Game.Campaign.MapParts: 3, Game.Runtime.TextBuffer);
  DrawText(false, 69, 130, Game.Runtime.TextBuffer);
  Game.Runtime.LastScan := ReadScanCode;
  SetVideoPage(0);

  if Reloaded then LoadResourceFile(Game.Runtime.PictureBanks[4], Game.Runtime.IslandPictureFileName);
  Game.Runtime.PicturePage := 0;
end;

procedure RitualSpellReport;
var
  I, Row: byte;

begin
  if CountRitualSpells > 0 then
  begin
    DrawDialog(8, 230, 488, 321);
    HeaderPrompt(6);
    Row := 0;
    DrawText(false, 2, 240, 'áÄäãàçÄçàü');

    for I := 0 to 7 do
      if Game.Campaign.Flags.SpellAvailable[I] then
      begin
        DrawText(false, 2, Row * 8 + 256, Game.Runtime.SpellTitles[I]);

        if Game.Campaign.Flags.SpellUsed[I] then DrawText(false, 15, Row * 8 + 256, SpellEffects[I]);
        Inc(Row);
      end;

    Game.Runtime.LastScan := ReadScanCode;
  end;
end;

procedure CastTornado;
var
  X, Y, Slot, Mask, X0, Y0: byte;

begin
  if Game.Campaign.TornadoCharges > 0 then
  begin
    X0 := Game.Campaign.Hero.X - 2;
    Y0 := Game.Campaign.Hero.Y - 2;
    Dec(Game.Campaign.TornadoCharges);
    Mask := 1;

    repeat
      for X := X0 to X0 + 4 do
        for Y := Y0 to Y0 + 4 do
          DrawMaskedTile(BattleCellOffsets[(Y - Y0) * 6 + (X - X0)], Game.Campaign.Map[Game.Campaign.Island, X, Y],
    Mask);
      Mask := Mask shl 1;
    until Mask = 16;

    for X := X0 to X0 + 4 do
      for Y := Y0 to Y0 + 4 do
        case Game.Campaign.Map[Game.Campaign.Island, X, Y] of
          5: begin
            Slot := FindWanderingArmy(X, Y);
            Game.Campaign.Map[Game.Campaign.Island, X, Y] := 0;
            RelocateArmy(Game.Campaign.Island, Slot);
          end;

          28: begin
            byte(Game.World.MageAge) := 0;
            Game.Campaign.Map[Game.Campaign.Island, Game.World.MagePosition.X, Game.World.MagePosition.Y] := 0;
            PlaceRoamingObject(Game.Campaign.Island, 28, Game.World.MagePosition);
          end;
        end;
  end
  else ShowNotice(24);
end;

procedure CargoReport;
var
  I: byte;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 17, 240, '#     å†™·.Ê•≠†(#1)');

  for I := 1 to 7 do
  begin
    DrawText(false, 5,(I - 1) * 8 + 256, GoodsNames[I]);
    Str(I, Game.Runtime.TextBuffer);
    Game.Runtime.TextBuffer := Game.Runtime.TextBuffer + ')';
    DrawText(false, 2,(I - 1) * 8 + 256, Game.Runtime.TextBuffer);
    Str(Game.Campaign.Cargo[I]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 16,(I - 1) * 8 + 256, Game.Runtime.TextBuffer);
    Str(Game.Campaign.CargoMaxPrices[I]: 3, Game.Runtime.TextBuffer);
    DrawText(false, 28,(I - 1) * 8 + 256, Game.Runtime.TextBuffer);
  end;

  Game.Runtime.LastScan := Ord(ReadKey);
  HeaderPrompt(0);
end;

procedure CurrentContract;
begin
  if Game.Campaign.ContractIsland < 6 then
  begin
    ContractReport(Game.Campaign.Contracts[Game.Campaign.ContractIsland, Game.Campaign.ContractSlot].Island,
      Game.Campaign.Contracts[Game.Campaign.ContractIsland, Game.Campaign.ContractSlot].Slot);
    Game.Runtime.LastScan := Ord(ReadKey);
  end
  else ShowNotice(8);
end;

procedure SeaVoyage;
label
  ChooseIsland, Finished;

var
  X, Y, Island: byte;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 256, '1) êa¢≠Æ´•·Ï•');

  if Game.Campaign.UnlockedIslands > 1 then DrawText(false, 2, 264, '2) á†°Æ´Æ‚®Ô');
  if Game.Campaign.UnlockedIslands > 2 then DrawText(false, 2, 272, '3) í†©£†≠®Ô');
  if Game.Campaign.UnlockedIslands > 3 then DrawText(false, 2, 280, '4) Ä´ÏØ®Ô');

  if Game.Campaign.UnlockedIslands > 4 then DrawText(false, 2, 288, '5) ë†Â†p®Ô');
  if (Game.Campaign.MapParts > 4) and (Game.Campaign.Difficulty = 3) then DrawText(false, 2, 296, '6) å†´Ï£p®¨®Ô');
ChooseIsland:
  repeat
    Game.Runtime.LastScan := Ord(ReadKey)
  until (Game.Runtime.LastScan in [49..54]) or (Game.Runtime.LastScan = 27);

  if Game.Runtime.LastScan = 27 then goto Finished;
  if (Game.Campaign.MapParts > 4) and (Game.Runtime.LastScan = 54) and (Game.Campaign.Difficulty = 3) then
    FirstSeriesEnding;
  Val(Chr(Game.Runtime.LastScan), Island, Game.World.GenerationLimit);

  if Game.Campaign.UnlockedIslands < Island then goto ChooseIsland;
  EnterIsland(Island);
  if Island = 5 then
    for X := 3 to 65 do
      for Y := 3 to 65 do
        if Game.Campaign.Map[5, X, Y] = 4 then
        begin
          Game.Runtime.ShoreTile := 32;

          if (Game.Campaign.Map[5, X, Y - 1] > 31) and (Game.Campaign.Map[5, X, Y - 1] < 48) then
    Inc(Game.Runtime.ShoreTile, 1);
          if (Game.Campaign.Map[5, X, Y + 1] > 31) and (Game.Campaign.Map[5, X, Y + 1] < 48) then
    Inc(Game.Runtime.ShoreTile, 2);
          if (Game.Campaign.Map[5, X - 1, Y] > 31) and (Game.Campaign.Map[5, X - 1, Y] < 48) then
    Inc(Game.Runtime.ShoreTile, 4);

          if (Game.Campaign.Map[5, X + 1, Y] > 31) and (Game.Campaign.Map[5, X + 1, Y] < 48) then
    Inc(Game.Runtime.ShoreTile, 8);
          Game.Campaign.Map[5, X, Y] := Game.Runtime.ShoreTile;
        end;

  if Game.Campaign.ExtraDays = 0 then Game.Campaign.Days := 1;
  Game.Campaign.Hero.X := 3;
  Game.Campaign.Hero.Y := 3;
Finished:
end;
end.
