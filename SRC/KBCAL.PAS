unit KBCal;
{$G+,R-,S-,I+,A+}

interface

procedure EndWeek;

implementation

uses KBHud, KBState, KBTables, KBUI, KBGfx, KBInput, KBWorld, KBSess;

procedure EndWeek;
var
  Payroll, Largest, Cost: longint;
  Remaining: word;
  I, LargestSlot: byte;
  Text: string[45];

procedure ReinforceEnemy;
label
  FoundSlot, Finished;

var
  I, J, Species, Island: byte;
  Total: longint;

begin
  Island := Random(Game.Campaign.UnlockedIslands) + 1;
  if Island > 5 then Island := 5;
  I := Random(5) + 1;

  if I > 5 then I := 5;
  if not Game.Campaign.Castles[Island, I].Owned then
  begin
    for I := 0 to 20 do
      if Game.Campaign.WanderingArmies[Island, I].X = 255 then
      begin
        RelocateArmy(Island, I);
        goto FoundSlot
      end;

    for I := 0 to 20 do
      if Game.Campaign.WanderingArmies[Island, I].Species[1] < 100 then
      begin
        Total := Game.Campaign.WanderingArmies[Island, I].Counts[1] *
          CreatureDefinitions[Game.Campaign.WanderingArmies[Island, I].Species[1]].Defense;
        if Game.Campaign.Leadership + Game.Campaign.LeadershipBonus > Total then goto FoundSlot;
      end
      else goto FoundSlot;
    goto Finished;
FoundSlot:
    for J := 0 to 4 do
    begin
      Species := Random(249) div 10;
      Game.Campaign.WanderingArmies[Island, I].Counts[J] := (Game.Campaign.Leadership +
    Game.Campaign.LeadershipBonus) div
        CreatureDefinitions[Species].Defense;
      if Game.Campaign.WanderingArmies[Island, I].Counts[J] > 1 then Game.Campaign.WanderingArmies[Island,
    I].Species[J] := Species;
    end;
  end;

Finished:
end;

procedure LoseEmptyCastles;
var
  Island, Slot, J, Species: byte;
  Total: longint;

begin
  for Island := 1 to 5 do
    for Slot := 1 to 5 do
      if Game.Campaign.Castles[Island, Slot].Owned then
      begin
        Total := 0;

        for J := 0 to 4 do if Game.Campaign.Castles[Island, Slot].Species[J] < 100 then Inc(Total);
        if Total = 0 then
        begin
          Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Castles[Island, Slot].X,
    Game.Campaign.Castles[Island, Slot].Y] := 2;
          Game.Campaign.Castles[Island, Slot].Owned := false;
          Dec(Game.Campaign.Income, IslandFactors[Island] * 20);
          Total := Game.Campaign.Leadership * 2;

          for J := 0 to 4 do
          begin
            Species := Random(24);
            Game.Campaign.Castles[Island, Slot].Counts[J] := Total div CreatureDefinitions[Species].Defense;

            if Game.Campaign.Castles[Island, Slot].Counts[J] > 0 then Game.Campaign.Castles[Island,
    Slot].Species[J] := Species;
          end;
        end;
      end;
end;

procedure RelocateRitualStone;
label
  FoundStone;

var
  Island, Ordinal, X, Y: byte;

begin
  Island := Random(49) div 10 + 1;
  Ordinal := Random(49) div 10 + 1;

  for X := 3 to 65 do
    for Y := 3 to 65 do
      if Game.Campaign.Map[Island, X, Y] = 22 then
      begin
        Dec(Ordinal);

        if Ordinal = 0 then goto FoundStone;
      end;

FoundStone:
  Game.Campaign.RitualStoneIsland := Island;
  Game.Campaign.RitualStonePosition.X := X;
  Game.Campaign.RitualStonePosition.Y := Y;
end;

begin
  Game.Campaign.Days := 200;
  Dec(Game.Campaign.Weeks);

  if Game.Campaign.Weeks = 0 then GameOver;
  Str(Game.Campaign.Weeks: 3, Game.Runtime.QuantityText);
  DrawText(false, 71, 8, Game.Runtime.QuantityText);
  Game.Campaign.Gold := Game.Campaign.Gold + Game.Campaign.Income;
  Game.Campaign.RitualPower := Game.Campaign.MagicPower;
  Game.World.TimeStopAccumulated := 0;

  repeat
    Payroll := 0;
    Largest := 0;
    LargestSlot := 0;

    for I := 0 to 9 do
      if Game.Campaign.Army[I].Species < 100 then
        if Game.Campaign.Army[I].Species < 25 then
        begin
          Cost := CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price;
          Cost := Cost * Game.Campaign.Army[I].Count div 20;

          if Cost > Largest then
          begin
            Largest := Cost;
            LargestSlot := I
          end;

          Payroll := Cost + Payroll;
        end
        else
          if CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price and 255 = 1 then
    Game.Campaign.Army[I].Species := 100
          else
          begin
            Remaining := CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price and 255;
            Dec(Remaining);
            CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price :=
    CreatureDefinitions[Game.Campaign.Army[I].Species].Cost
              .Price and $FF00;
            CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price :=
    CreatureDefinitions[Game.Campaign.Army[I].Species].Cost
              .Price or Remaining;
          end;

    if Payroll > Game.Campaign.Gold then
    begin
      Cost := CreatureDefinitions[Game.Campaign.Army[LargestSlot].Species].Cost.Price;
      Game.Campaign.Gold := Game.Campaign.Gold + Cost * Game.Campaign.Army[LargestSlot].Count div 100;
      Payroll := Payroll - Largest;
      Game.Campaign.Army[LargestSlot].Species := 100;
    end;
  until Game.Campaign.Gold > Payroll;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 13, 240, 'ФИНАНСОВЫЙ ОТЧЕТ ПРОШЕДШЕЙ НЕДЕЛИ');
  DrawText(false, 2, 264, 'Имеется всего ($) :');
  Str(Game.Campaign.Gold, Text);
  DrawText(false, 22, 264, Text);
  DrawText(false, 2, 272, 'Недельная пpибавка:');
  Str(Game.Campaign.Income, Text);
  DrawText(false, 22, 272, Text);
  DrawText(false, 2, 280, 'Расходы на аpмию  :');
  Str(Payroll, Text);
  DrawText(false, 22, 280, Text);
  Game.Campaign.Gold := Game.Campaign.Gold - Payroll;
  LoseEmptyCastles;
  Game.Runtime.LastScan := ReadScanCode;
  Game.Campaign.WeeklySpecies := Random(24);
  Text := CreatureDefinitions[Game.Campaign.WeeklySpecies].Name + ' активизиpуются.';
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, Text);
  DrawText(false, 2, 256, 'Наступает благопpиятный пеpиод по pасположению звезд для');
  DrawText(false, 2, 264, 'этиx воинов.');
  DrawText(false, 2, 272, 'Все их жилища пеpенаселяются.');

  for I := 1 to 5 do
    for LargestSlot := 0 to 7 do
      if Game.Campaign.Dwellings[I, LargestSlot].Species = Game.Campaign.WeeklySpecies then
        Game.Campaign.Dwellings[I, LargestSlot].Count := WeeklyDwellingCapacities[Game.Campaign.WeeklySpecies];
  Game.Runtime.WorkerRestockPhase := not Game.Runtime.WorkerRestockPhase;

  if Game.Runtime.WorkerRestockPhase then
  begin
    I := Random(4);
    Inc(I);
    LargestSlot := Random(4);
    Inc(LargestSlot);
    Text := 'Гоpод ' + TownNames[Game.Campaign.Towns[LargestSlot, I].Name] + ' заполнился pаботниками.';
    DrawText(false, 2, 288, Text);
    Game.Campaign.Towns[LargestSlot, I].Workers[1] := WorkerCapacities[LargestSlot, I, 0];
    Game.Campaign.Towns[LargestSlot, I].Workers[2] := WorkerCapacities[LargestSlot, I, 1];
    Game.Campaign.Towns[LargestSlot, I].Workers[3] := WorkerCapacities[LargestSlot, I, 2];
    Game.Campaign.Towns[LargestSlot, I].Workers[4] := WorkerCapacities[LargestSlot, I, 3];
  end;

  ReinforceEnemy;
  RefreshGold;
  RelocateRitualStone;
  Game.Campaign.LeadershipBonus := 0;
  Game.Runtime.LastScan := ReadScanCode;
  HeaderPrompt(0);
end;

end.
