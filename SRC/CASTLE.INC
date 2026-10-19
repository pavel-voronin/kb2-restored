procedure CastleVisit;
var
  I: shortint;
  Slot, UnknownLocal: byte;
  Text: string[80];
  ReserveSelected: boolean;
  ActiveRows: array[1..5] of byte;
  UnknownAfterActiveRows: byte;
  ReserveRows: array[1..5] of byte;
  UnknownAfterReserveRows: byte;
  Overflow: TArmyStack;
  OriginalArmy: array[0..4] of TArmyStack;

procedure Audience;
begin
  DrawDialog(8, 230, 488, 320);
  Text := 'Хозяин земли ' + RulerNames[Game.Island] + ' говоpит, что';
  DrawText(false, 2, 240, Text);

  if Game.QuestFlags[Game.Island] = 0 then
  begin
    DrawText(false, 2, 256, 'Он благодаpит Вас за помощь его землям и пpедлагает:');
    DrawText(false, 2, 264, '1) Золото - $500000');
    DrawText(false, 2, 272, '2) Войско');
    DrawText(false, 2, 280, '3) Часть дpевней каpты');
    DrawText(false, 2, 288, '4) Звание Главного полководца его земель');
    TransmuteDwellings(Game.Island);

    repeat
      Game.LastScan := Ord(ReadKey)
    until Game.LastScan in [49..52];

    case Game.LastScan of
      49: Game.Gold := Game.Gold + 500000;
      50: begin
        I := -1;

        repeat
          Inc(I)
        until (Game.Army[I].Species < 100) or (I > 4);

        if I < 4 then Game.Army[I].Count := Game.Army[I].Count * 2;
      end;

      51: begin
        if Game.WizardVisited[Game.Island] and 2 = 0 then Inc(Game.MapParts);
          Inc(Game.MagicPower, 5);
          Inc(Game.ScrollCapacity, 10);
          RefreshMapParts;
          Game.WizardVisited[Game.Island] := Game.WizardVisited[Game.Island] or 2;
      end;

      52: begin
        Inc(Game.Leadership, 1000);
        Inc(Game.MagicPower, 8);
        Inc(Game.ScrollCapacity, 15);
      end;
    end;

    Inc(Game.Income, Game.Island * 2000);
    Game.QuestFlags[Game.Island] := 100;
    RefreshMagic;
    RefreshDwellings;
    RefreshGold;
  end
  else if Game.WizardVisited[Game.Island] and 1 > 0 then
  begin
    Str(Game.QuestFlags[Game.Island], Text);

    case Game.QuestFlags[Game.Island] of
      1: Text := 'Вы должны взять ' + Text + ' замок';
      2..4: Text := 'Вы должны взять ' + Text + ' замкa';
      5: Text := 'Вы должны взять ' + Text + ' замков';
    else
    begin
      Game.QuestFlags[Game.Island] := 100;
      Text := 'Их Величество очень обижено и не желает больше Вас видеть!' end;
    end;

    DrawText(false, 2, 256, Text);
    DrawText(false, 27, 256, 'из числа пpедлагаемых по контpак-');
    DrawText(false, 2, 266, 'ту в гоpодах его Земли.');
    Game.LastScan := ReadScanCode;
  end
  else
  begin
    Game.WizardVisited[Game.Island] := Game.WizardVisited[Game.Island] or 1;
    DrawText(false, 2, 256, 'он pад пpиветствовать Вас на своей Земле и надеется, что');
    DrawText(false, 2, 266, 'это знакомтво будет плодотвоpным для обеих стоpон.');
    DrawText(false, 2, 276, 'Некотоpые хозяева замков вынашивают коваpные планы захва-');
    DrawText(false, 2, 286, 'та его Земли. Если это пpоизойдет,  хаос и мpак  надолго');
    DrawText(false, 2, 296, 'воцаpят в его стpане.Хозяин Земли надеется на Вашу помощь.');
    Game.LastScan := ReadScanCode;
  end;

  Game.LastScan := 27;
end;

procedure SiegeBattle;
var
  PreviousGold: longint;

begin
  PreviousGold := Game.Gold;
  Battle(@Game.Castles[Game.Island, Slot].Species, @Game.Castles[Game.Island, Slot].Counts, 0);

  if Game.BattleResult = 2 then DefeatReport
  else
  begin
    Game.Map[Game.Island, Game.Castles[Game.Island, Slot].X, Game.Castles[Game.Island, Slot].Y] := 18;
    Game.Castles[Game.Island, Slot].Owned := true;
    Inc(Game.Income, IslandIncomeFactors[Game.Island] * 20);

    if Game.WizardVisited[Game.Island] and 1 = 0 then Inc(Game.QuestFlags[Game.Island]);
    if (Slot = 1) and (Game.WizardVisited[Game.Island] and 2 = 0) then
    begin
      Game.WizardVisited[Game.Island] := Game.WizardVisited[Game.Island] or 2;
      Inc(Game.MapParts);
    end;

    VictoryReport(Slot, 2);
    if (Game.ContractIsland < 6) and (Game.Contracts[Game.ContractIsland, Game.ContractSlot].Island = Game.Island)
      and (Game.Contracts[Game.ContractIsland, Game.ContractSlot].Slot = Slot) then
    begin
      Game.Contracts[Game.ContractIsland, Game.ContractSlot].Island := 100;

      if Game.QuestFlags[Game.ContractIsland] > 0 then Dec(Game.QuestFlags[Game.ContractIsland]);
      Game.Gold := Game.Gold + (Game.Gold - PreviousGold) div 10;
      Game.ContractIsland := 100;
    end;
  end;

  RestoreControls;
end;

procedure ToggleGarrison;
begin
  ReserveSelected := not ReserveSelected;
  DrawArmyCaption(ReserveSelected, 256, 'ОХРАНА ЗАМКА');
end;

procedure DrawGarrison;
var
  J: byte;

begin
  I := 0;
  DrawDialog(8, 230, 488, 321);
  DrawText(false, 2, 240, 'Замок');
  DrawText(false, 9, 240, CastleNames[Game.Castles[Game.Island, Slot].Name]);
  ToggleGarrison;

  for J := 0 to 4 do
    if Game.Army[J].Species < 100 then
    begin
      Inc(I);
      ActiveRows[I] := J;
      Game.AuthorityChange := I * 8 + 264;
      Str(I, Game.TextBuffer);
      Text := Game.TextBuffer + ') ' + CreatureDefinitions[Game.Army[J].Species].Name;
      DrawText(false, 3, Game.AuthorityChange, Text);
      Str(Game.Army[J].Count, Game.TextBuffer);
      DrawText(false, 16, Game.AuthorityChange, Game.TextBuffer);
    end;

  I := 0;
  for J := 0 to 4 do
    if Game.Castles[Game.Island, Slot].Species[J] < 100 then
    begin
      Inc(I);
      ReserveRows[I] := J;
      Game.AuthorityChange := I * 8 + 264;
      Str(I, Game.TextBuffer);
      Text := Game.TextBuffer + ') ' + CreatureDefinitions[Game.Castles[Game.Island, Slot].Species[J]].Name;
      DrawText(false, 42, Game.AuthorityChange, Text);
      Str(Game.Castles[Game.Island, Slot].Counts[J], Game.TextBuffer);
      DrawText(false, 55, Game.AuthorityChange, Game.TextBuffer);
    end;

  if Overflow.Species < 100 then
  begin
    Text := '6) ' + CreatureDefinitions[Overflow.Species].Name;
    DrawText(false, 42, 304, Text);
    Str(Overflow.Count, Game.TextBuffer);
    DrawText(false, 55, 304, Game.TextBuffer);
  end;
end;

procedure TransferGarrison;
label
  Finished, MergeStack, ActiveFree, CastleFree, Redraw, ReplaceCastle;

var
  J: byte;

begin
  Val(Chr(Game.LastScan), I, Game.AuthorityChange);
  if ReserveSelected then
  begin
    if I = 6 then
    begin
      if Overflow.Species = 100 then
      begin
        ShowNotice(12);
        DrawGarrison;
        goto Finished
      end;
    end
    else if Game.Castles[Game.Island, Slot].Species[ReserveRows[I]] = 100 then
    begin
      ShowNotice(12);
      DrawGarrison;
      goto Finished;
    end;

    for J := 0 to 9 do
      if Game.Army[J].Species = Game.Castles[Game.Island, Slot].Species[ReserveRows[I]] then goto MergeStack;
    for J := 0 to 4 do if Game.Army[J].Species = 100 then goto ActiveFree;
    ShowNotice(10);
    DrawGarrison;
    goto Finished;
MergeStack:
    Inc(Game.Army[J].Count, Game.Castles[Game.Island, Slot].Counts[ReserveRows[I]]);
    goto ReplaceCastle;
ActiveFree:
    Game.Army[J].Species := Game.Castles[Game.Island, Slot].Species[ReserveRows[I]];
    Game.Army[J].Count := Game.Castles[Game.Island, Slot].Counts[ReserveRows[I]];
ReplaceCastle:
    if Overflow.Species < 100 then
    begin
      Game.Castles[Game.Island, Slot].Species[ReserveRows[I]] := Overflow.Species;
      Game.Castles[Game.Island, Slot].Counts[ReserveRows[I]] := Overflow.Count;
      Overflow.Species := 100;
    end
    else Game.Castles[Game.Island, Slot].Species[ReserveRows[I]] := 100;
  end
  else
  begin
    if Game.Army[ActiveRows[I]].Species = 100 then
    begin
      ShowNotice(12);
      DrawGarrison;
      goto Finished;
    end;

    for J := 0 to 4 do if Game.Castles[Game.Island, Slot].Species[J] = 100 then goto CastleFree;
    if Overflow.Species < 100 then
    begin
      ShowNotice(11);
      DrawGarrison;
      goto Finished;
    end
    else
    begin
      Overflow := Game.Army[ActiveRows[I]];
      Game.Army[ActiveRows[I]].Species := 100;
    end;

    goto Redraw;
CastleFree:
    Game.Castles[Game.Island, Slot].Species[J] := Game.Army[ActiveRows[I]].Species;
    Game.Castles[Game.Island, Slot].Counts[J] := Game.Army[ActiveRows[I]].Count;
    Game.Army[ActiveRows[I]].Species := 100;
  end;

Redraw:
  DrawGarrison;
Finished:
end;

procedure GarrisonVisit;
var
  J: byte;

begin
  HeaderPrompt(24);
  FillChar(Overflow, 3, 100);
  FillChar(ReserveRows, 5, 0);
  FillChar(ActiveRows, 5, 0);

  for J := 0 to 4 do OriginalArmy[J] := Game.Army[J];
  DrawGarrison;
  repeat
    Game.LastScan := Ord(ReadKey);

    case Game.LastScan of
      9: ToggleGarrison;
      49..54: TransferGarrison;
    end;
  until Game.LastScan = 27;

  for J := 0 to 4 do
  begin
    if Game.Castles[Game.Island, Slot].Species[J] in [25..29] then Game.Castles[Game.Island, Slot].Species[J] := 100;

    if (OriginalArmy[J].Species <> Game.Army[J].Species) and (Game.Army[J].Species < 100) then
    begin
      LoadCreatureArt(Game.Army[J].Species);
      CopyRecord(0, J, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
    end;
  end;

  Game.LastScan := 48;
  HeaderPrompt(0);
end;

begin
  if Game.GenerationY <= Game.Hero.Y then
  begin
    Slot := 0;
    I := -1;

    repeat
      Inc(Slot)
    until (Game.Castles[Game.Island, Slot].X = Game.GenerationX)
      and (Game.Castles[Game.Island, Slot].Y = Game.GenerationY);
    if Game.Castles[Game.Island, Slot].Owned then GarrisonVisit
    else
    begin
      repeat
        Inc(I)
      until ((Game.VisitedCastles[I].Island = Game.Island) and (Game.VisitedCastles[I].Slot = Slot))
        or (I = 25);
      if I = 25 then
      begin
        I := 0;

        while Game.VisitedCastles[I].Island > 0 do Inc(I);
        Game.VisitedCastles[I].Island := Game.Island;
        Game.VisitedCastles[I].Slot := Slot;
      end;

      DrawDialog(8, 230, 488, 320);
      DrawText(false, 2, 240, 'Замок');
      DrawText(false, 9, 240, CastleNames[Game.Castles[Game.Island, Slot].Name]);

      if (Slot = 1) and (Game.QuestFlags[Game.Island] < 10) then
      begin
        DrawText(true, 25, 240, 'Хозяин Земли');

        if Game.LocalMapOwned[Game.Island] then DrawText(false, 2, 256, '*) Kаpтa земли куплена')
        else
        begin
          Game.AuthorityChange := Game.Island * 3000;
          Str(Game.AuthorityChange, Text);
          Text := '1) Купить каpту земли ($' + Text + ')';
          DrawText(false, 2, 256, Text);
        end;

        DrawText(false, 2, 264, '2) Визит к хозяину земли');
        DrawText(false, 2, 272, '3) Объявить войну хозяину земли');
        repeat
          Game.LastScan := Ord(ReadKey);

          case Game.LastScan of
            49: if not PaymentFailed(Game.Island * 3000) then
            begin
              Game.LocalMapOwned[Game.Island] := true;
              DrawText(false, 2, 256, '*) Kаpтa земли куплена        ');
            end;

            50: Audience;
            51: begin
              Game.QuestFlags[Game.Island] := 100;
              Game.LastScan := 27
            end;
          end;
        until Game.LastScan = 27;
      end
      else
      begin
        I := Random(5);

        case I of
          0: DrawText(false, 6, 264, 'Деpжись подальше от этого замка, иначе ты покойник !');
          1: DrawText(false, 12, 264, 'Иди, выкопай себе могилу и тогда пpиходи.');
          2: DrawText(false, 10, 264, 'Я магистp чеpной магии, а ты пpостой смеpтный.');
          3: DrawText(false, 9, 264, 'Пpоходи мимо, не задеpживайся. Ты здесь не нужен.');
          4: DrawText(false, 13, 264, 'Заходи, pыцаpь, мне как pаз нужны pабы.');
          5: DrawText(false, 14, 264, 'Чужеземец, что ты забыл в моем замке ?');
        end;

        DrawText(false, 20, 304, 'Обидеться? (Y-да/N-нет)');
        Game.LastScan := ReadScanCode;
        if Game.LastScan = 21 then
          if Game.SiegeEngineOwned then
            if not Game.ArmyAvailable then GameOver
            else SiegeBattle
          else ShowNotice(7);
      end;
    end;
  end;
end;
