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
  Island := Random(Game.UnlockedIslands) + 1;
  if Island > 5 then Island := 5;
  I := Random(5) + 1;

  if I > 5 then I := 5;
  if not Game.Castles[Island, I].Owned then
  begin
    for I := 0 to 20 do
      if Game.WanderingArmies[Island, I].X = 255 then
      begin
        RelocateArmy(Island, I);
        goto FoundSlot
      end;

    for I := 0 to 20 do
      if Game.WanderingArmies[Island, I].Species[1] < 100 then
      begin
        Total := Game.WanderingArmies[Island, I].Counts[1] *
          CreatureDefinitions[Game.WanderingArmies[Island, I].Species[1]].Defense;
        if Game.Leadership + Game.LeadershipBonus > Total then goto FoundSlot;
      end
      else goto FoundSlot;
    goto Finished;
FoundSlot:
    for J := 0 to 4 do
    begin
      Species := Random(249) div 10;
      Game.WanderingArmies[Island, I].Counts[J] := (Game.Leadership + Game.LeadershipBonus) div
        CreatureDefinitions[Species].Defense;
      if Game.WanderingArmies[Island, I].Counts[J] > 1 then Game.WanderingArmies[Island, I].Species[J] := Species;
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
      if Game.Castles[Island, Slot].Owned then
      begin
        Total := 0;

        for J := 0 to 4 do if Game.Castles[Island, Slot].Species[J] < 100 then Inc(Total);
        if Total = 0 then
        begin
          Game.Map[Game.Island, Game.Castles[Island, Slot].X, Game.Castles[Island, Slot].Y] := 2;
          Game.Castles[Island, Slot].Owned := false;
          Dec(Game.Income, IslandFactors[Island] * 20);
          Total := Game.Leadership * 2;

          for J := 0 to 4 do
          begin
            Species := Random(24);
            Game.Castles[Island, Slot].Counts[J] := Total div CreatureDefinitions[Species].Defense;

            if Game.Castles[Island, Slot].Counts[J] > 0 then Game.Castles[Island, Slot].Species[J] := Species;
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
      if Game.Map[Island, X, Y] = 22 then
      begin
        Dec(Ordinal);

        if Ordinal = 0 then goto FoundStone;
      end;

FoundStone:
  Game.RitualStoneIsland := Island;
  Game.RitualStonePosition.X := X;
  Game.RitualStonePosition.Y := Y;
end;

begin
  Game.Days := 200;
  Dec(Game.Weeks);

  if Game.Weeks = 0 then GameOver;
  Str(Game.Weeks: 3, Game.QuantityText);
  DrawText(false, 71, 8, Game.QuantityText);
  Game.Gold := Game.Gold + Game.Income;
  Game.RitualPower := Game.MagicPower;
  Game.TimeStopAccumulated := 0;

  repeat
    Payroll := 0;
    Largest := 0;
    LargestSlot := 0;

    for I := 0 to 9 do
      if Game.Army[I].Species < 100 then
        if Game.Army[I].Species < 25 then
        begin
          Cost := CreatureDefinitions[Game.Army[I].Species].Cost.Price;
          Cost := Cost * Game.Army[I].Count div 20;

          if Cost > Largest then
          begin
            Largest := Cost;
            LargestSlot := I
          end;

          Payroll := Cost + Payroll;
        end
        else
          if CreatureDefinitions[Game.Army[I].Species].Cost.Price and 255 = 1 then Game.Army[I].Species := 100
          else
          begin
            Remaining := CreatureDefinitions[Game.Army[I].Species].Cost.Price and 255;
            Dec(Remaining);
            CreatureDefinitions[Game.Army[I].Species].Cost.Price := CreatureDefinitions[Game.Army[I].Species].Cost
              .Price and $FF00;
            CreatureDefinitions[Game.Army[I].Species].Cost.Price := CreatureDefinitions[Game.Army[I].Species].Cost
              .Price or Remaining;
          end;

    if Payroll > Game.Gold then
    begin
      Cost := CreatureDefinitions[Game.Army[LargestSlot].Species].Cost.Price;
      Game.Gold := Game.Gold + Cost * Game.Army[LargestSlot].Count div 100;
      Payroll := Payroll - Largest;
      Game.Army[LargestSlot].Species := 100;
    end;
  until Game.Gold > Payroll;
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 13, 240, 'ФИНАНСОВЫЙ ОТЧЕТ ПРОШЕДШЕЙ НЕДЕЛИ');
  DrawText(false, 2, 264, 'Имеется всего ($) :');
  Str(Game.Gold, Text);
  DrawText(false, 22, 264, Text);
  DrawText(false, 2, 272, 'Недельная пpибавка:');
  Str(Game.Income, Text);
  DrawText(false, 22, 272, Text);
  DrawText(false, 2, 280, 'Расходы на аpмию  :');
  Str(Payroll, Text);
  DrawText(false, 22, 280, Text);
  Game.Gold := Game.Gold - Payroll;
  LoseEmptyCastles;
  Game.LastScan := ReadScanCode;
  Game.WeeklySpecies := Random(24);
  Text := CreatureDefinitions[Game.WeeklySpecies].Name + ' активизиpуются.';
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, Text);
  DrawText(false, 2, 256, 'Наступает благопpиятный пеpиод по pасположению звезд для');
  DrawText(false, 2, 264, 'этиx воинов.');
  DrawText(false, 2, 272, 'Все их жилища пеpенаселяются.');

  for I := 1 to 5 do
    for LargestSlot := 0 to 7 do
      if Game.Dwellings[I, LargestSlot].Species = Game.WeeklySpecies then
        Game.Dwellings[I, LargestSlot].Count := WeeklyDwellingCapacities[Game.WeeklySpecies];
  Game.WorkerRestockPhase := not Game.WorkerRestockPhase;

  if Game.WorkerRestockPhase then
  begin
    I := Random(4);
    Inc(I);
    LargestSlot := Random(4);
    Inc(LargestSlot);
    Text := 'Гоpод ' + TownNames[Game.Towns[LargestSlot, I].Name] + ' заполнился pаботниками.';
    DrawText(false, 2, 288, Text);
    Game.Towns[LargestSlot, I].Workers[1] := WorkerCapacities[LargestSlot, I, 0];
    Game.Towns[LargestSlot, I].Workers[2] := WorkerCapacities[LargestSlot, I, 1];
    Game.Towns[LargestSlot, I].Workers[3] := WorkerCapacities[LargestSlot, I, 2];
    Game.Towns[LargestSlot, I].Workers[4] := WorkerCapacities[LargestSlot, I, 3];
  end;

  ReinforceEnemy;
  RefreshGold;
  RelocateRitualStone;
  Game.LeadershipBonus := 0;
  Game.LastScan := ReadScanCode;
  HeaderPrompt(0);
end;
