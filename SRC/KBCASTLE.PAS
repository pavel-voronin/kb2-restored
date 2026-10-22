unit KBCastle;
{$G+,R-,S-,I+,A+}

interface

procedure CastleVisit;

implementation

uses KBAdvent, KBBattle, KBSess, KBEcon, KBHud, KBTables, KBUI, KBArt, KBGfx, KBInput, KBFiles, Crt, KBTypes, KBState;

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
  Text := 'Хозяин земли ' + RulerNames[Game.Campaign.Island] + ' говоpит, что';
  DrawText(false, 2, 240, Text);

  if Game.Campaign.QuestFlags[Game.Campaign.Island] = 0 then
  begin
    DrawText(false, 2, 256, 'Он благодаpит Вас за помощь его землям и пpедлагает:');
    DrawText(false, 2, 264, '1) Золото - $500000');
    DrawText(false, 2, 272, '2) Войско');
    DrawText(false, 2, 280, '3) Часть дpевней каpты');
    DrawText(false, 2, 288, '4) Звание Главного полководца его земель');
    TransmuteDwellings(Game.Campaign.Island);

    repeat
      Game.Runtime.LastScan := Ord(ReadKey)
    until Game.Runtime.LastScan in [49..52];

    case Game.Runtime.LastScan of
      49: Game.Campaign.Gold := Game.Campaign.Gold + 500000;
      50: begin
        I := -1;

        repeat
          Inc(I)
        until (Game.Campaign.Army[I].Species < 100) or (I > 4);

        if I < 4 then Game.Campaign.Army[I].Count := Game.Campaign.Army[I].Count * 2;
      end;

      51: begin
        if Game.Campaign.WizardVisited[Game.Campaign.Island] and 2 = 0 then Inc(Game.Campaign.MapParts);
          Inc(Game.Campaign.MagicPower, 5);
          Inc(Game.Campaign.ScrollCapacity, 10);
          RefreshMapParts;
          Game.Campaign.WizardVisited[Game.Campaign.Island] := Game.Campaign.WizardVisited[Game.Campaign.Island] or 2;
      end;

      52: begin
        Inc(Game.Campaign.Leadership, 1000);
        Inc(Game.Campaign.MagicPower, 8);
        Inc(Game.Campaign.ScrollCapacity, 15);
      end;
    end;

    Inc(Game.Campaign.Income, Game.Campaign.Island * 2000);
    Game.Campaign.QuestFlags[Game.Campaign.Island] := 100;
    RefreshMagic;
    RefreshDwellings;
    RefreshGold;
  end
  else if Game.Campaign.WizardVisited[Game.Campaign.Island] and 1 > 0 then
  begin
    Str(Game.Campaign.QuestFlags[Game.Campaign.Island], Text);

    case Game.Campaign.QuestFlags[Game.Campaign.Island] of
      1: Text := 'Вы должны взять ' + Text + ' замок';
      2..4: Text := 'Вы должны взять ' + Text + ' замкa';
      5: Text := 'Вы должны взять ' + Text + ' замков';
    else
    begin
      Game.Campaign.QuestFlags[Game.Campaign.Island] := 100;
      Text := 'Их Величество очень обижено и не желает больше Вас видеть!' end;
    end;

    DrawText(false, 2, 256, Text);
    DrawText(false, 27, 256, 'из числа пpедлагаемых по контpак-');
    DrawText(false, 2, 266, 'ту в гоpодах его Земли.');
    Game.Runtime.LastScan := ReadScanCode;
  end
  else
  begin
    Game.Campaign.WizardVisited[Game.Campaign.Island] := Game.Campaign.WizardVisited[Game.Campaign.Island] or 1;
    DrawText(false, 2, 256, 'он pад пpиветствовать Вас на своей Земле и надеется, что');
    DrawText(false, 2, 266, 'это знакомтво будет плодотвоpным для обеих стоpон.');
    DrawText(false, 2, 276, 'Некотоpые хозяева замков вынашивают коваpные планы захва-');
    DrawText(false, 2, 286, 'та его Земли. Если это пpоизойдет,  хаос и мpак  надолго');
    DrawText(false, 2, 296, 'воцаpят в его стpане.Хозяин Земли надеется на Вашу помощь.');
    Game.Runtime.LastScan := ReadScanCode;
  end;

  Game.Runtime.LastScan := 27;
end;

procedure SiegeBattle;
var
  PreviousGold: longint;

begin
  PreviousGold := Game.Campaign.Gold;
  Battle(@Game.Campaign.Castles[Game.Campaign.Island, Slot].Species, @Game.Campaign.Castles[Game.Campaign.Island,
    Slot].Counts, 0);

  if Game.Runtime.BattleResult = 2 then DefeatReport
  else
  begin
    Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Castles[Game.Campaign.Island, Slot].X,
    Game.Campaign.Castles[Game.Campaign.Island, Slot].Y] := 18;
    Game.Campaign.Castles[Game.Campaign.Island, Slot].Owned := true;
    Inc(Game.Campaign.Income, IslandIncomeFactors[Game.Campaign.Island] * 20);

    if Game.Campaign.WizardVisited[Game.Campaign.Island] and 1 = 0 then
    Inc(Game.Campaign.QuestFlags[Game.Campaign.Island]);
    if (Slot = 1) and (Game.Campaign.WizardVisited[Game.Campaign.Island] and 2 = 0) then
    begin
      Game.Campaign.WizardVisited[Game.Campaign.Island] := Game.Campaign.WizardVisited[Game.Campaign.Island] or 2;
      Inc(Game.Campaign.MapParts);
    end;

    VictoryReport(Slot, 2);
    if (Game.Campaign.ContractIsland < 6) and (Game.Campaign.Contracts[Game.Campaign.ContractIsland,
    Game.Campaign.ContractSlot].Island = Game.Campaign.Island)
      and (Game.Campaign.Contracts[Game.Campaign.ContractIsland, Game.Campaign.ContractSlot].Slot = Slot) then
    begin
      Game.Campaign.Contracts[Game.Campaign.ContractIsland, Game.Campaign.ContractSlot].Island := 100;

      if Game.Campaign.QuestFlags[Game.Campaign.ContractIsland] > 0 then
    Dec(Game.Campaign.QuestFlags[Game.Campaign.ContractIsland]);
      Game.Campaign.Gold := Game.Campaign.Gold + (Game.Campaign.Gold - PreviousGold) div 10;
      Game.Campaign.ContractIsland := 100;
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
  DrawText(false, 9, 240, CastleNames[Game.Campaign.Castles[Game.Campaign.Island, Slot].Name]);
  ToggleGarrison;

  for J := 0 to 4 do
    if Game.Campaign.Army[J].Species < 100 then
    begin
      Inc(I);
      ActiveRows[I] := J;
      Game.Runtime.AuthorityChange := I * 8 + 264;
      Str(I, Game.Runtime.TextBuffer);
      Text := Game.Runtime.TextBuffer + ') ' + CreatureDefinitions[Game.Campaign.Army[J].Species].Name;
      DrawText(false, 3, Game.Runtime.AuthorityChange, Text);
      Str(Game.Campaign.Army[J].Count, Game.Runtime.TextBuffer);
      DrawText(false, 16, Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
    end;

  I := 0;
  for J := 0 to 4 do
    if Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[J] < 100 then
    begin
      Inc(I);
      ReserveRows[I] := J;
      Game.Runtime.AuthorityChange := I * 8 + 264;
      Str(I, Game.Runtime.TextBuffer);
      Text := Game.Runtime.TextBuffer + ') ' + CreatureDefinitions[Game.Campaign.Castles[Game.Campaign.Island,
    Slot].Species[J]].Name;
      DrawText(false, 42, Game.Runtime.AuthorityChange, Text);
      Str(Game.Campaign.Castles[Game.Campaign.Island, Slot].Counts[J], Game.Runtime.TextBuffer);
      DrawText(false, 55, Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
    end;

  if Overflow.Species < 100 then
  begin
    Text := '6) ' + CreatureDefinitions[Overflow.Species].Name;
    DrawText(false, 42, 304, Text);
    Str(Overflow.Count, Game.Runtime.TextBuffer);
    DrawText(false, 55, 304, Game.Runtime.TextBuffer);
  end;
end;

procedure TransferGarrison;
label
  Finished, MergeStack, ActiveFree, CastleFree, Redraw, ReplaceCastle;

var
  J: byte;

begin
  Val(Chr(Game.Runtime.LastScan), I, Game.Runtime.AuthorityChange);
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
    else if Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[ReserveRows[I]] = 100 then
    begin
      ShowNotice(12);
      DrawGarrison;
      goto Finished;
    end;

    for J := 0 to 9 do
      if Game.Campaign.Army[J].Species = Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[ReserveRows[I]]
    then goto MergeStack;
    for J := 0 to 4 do if Game.Campaign.Army[J].Species = 100 then goto ActiveFree;
    ShowNotice(10);
    DrawGarrison;
    goto Finished;
MergeStack:
    Inc(Game.Campaign.Army[J].Count, Game.Campaign.Castles[Game.Campaign.Island, Slot].Counts[ReserveRows[I]]);
    goto ReplaceCastle;
ActiveFree:
    Game.Campaign.Army[J].Species := Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[ReserveRows[I]];
    Game.Campaign.Army[J].Count := Game.Campaign.Castles[Game.Campaign.Island, Slot].Counts[ReserveRows[I]];
ReplaceCastle:
    if Overflow.Species < 100 then
    begin
      Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[ReserveRows[I]] := Overflow.Species;
      Game.Campaign.Castles[Game.Campaign.Island, Slot].Counts[ReserveRows[I]] := Overflow.Count;
      Overflow.Species := 100;
    end
    else Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[ReserveRows[I]] := 100;
  end
  else
  begin
    if Game.Campaign.Army[ActiveRows[I]].Species = 100 then
    begin
      ShowNotice(12);
      DrawGarrison;
      goto Finished;
    end;

    for J := 0 to 4 do if Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[J] = 100 then goto CastleFree;
    if Overflow.Species < 100 then
    begin
      ShowNotice(11);
      DrawGarrison;
      goto Finished;
    end
    else
    begin
      Overflow := Game.Campaign.Army[ActiveRows[I]];
      Game.Campaign.Army[ActiveRows[I]].Species := 100;
    end;

    goto Redraw;
CastleFree:
    Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[J] := Game.Campaign.Army[ActiveRows[I]].Species;
    Game.Campaign.Castles[Game.Campaign.Island, Slot].Counts[J] := Game.Campaign.Army[ActiveRows[I]].Count;
    Game.Campaign.Army[ActiveRows[I]].Species := 100;
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

  for J := 0 to 4 do OriginalArmy[J] := Game.Campaign.Army[J];
  DrawGarrison;
  repeat
    Game.Runtime.LastScan := Ord(ReadKey);

    case Game.Runtime.LastScan of
      9: ToggleGarrison;
      49..54: TransferGarrison;
    end;
  until Game.Runtime.LastScan = 27;

  for J := 0 to 4 do
  begin
    if Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[J] in [25..29] then
    Game.Campaign.Castles[Game.Campaign.Island, Slot].Species[J] := 100;

    if (OriginalArmy[J].Species <> Game.Campaign.Army[J].Species) and (Game.Campaign.Army[J].Species < 100) then
    begin
      LoadCreatureArt(Game.Campaign.Army[J].Species);
      CopyRecord(0, J, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
    end;
  end;

  Game.Runtime.LastScan := 48;
  HeaderPrompt(0);
end;

begin
  if Game.World.GenerationY <= Game.Campaign.Hero.Y then
  begin
    Slot := 0;
    I := -1;

    repeat
      Inc(Slot)
    until (Game.Campaign.Castles[Game.Campaign.Island, Slot].X = Game.World.GenerationX)
      and (Game.Campaign.Castles[Game.Campaign.Island, Slot].Y = Game.World.GenerationY);
    if Game.Campaign.Castles[Game.Campaign.Island, Slot].Owned then GarrisonVisit
    else
    begin
      repeat
        Inc(I)
      until ((Game.Campaign.VisitedCastles[I].Island = Game.Campaign.Island) and
    (Game.Campaign.VisitedCastles[I].Slot = Slot))
        or (I = 25);
      if I = 25 then
      begin
        I := 0;

        while Game.Campaign.VisitedCastles[I].Island > 0 do Inc(I);
        Game.Campaign.VisitedCastles[I].Island := Game.Campaign.Island;
        Game.Campaign.VisitedCastles[I].Slot := Slot;
      end;

      DrawDialog(8, 230, 488, 320);
      DrawText(false, 2, 240, 'Замок');
      DrawText(false, 9, 240, CastleNames[Game.Campaign.Castles[Game.Campaign.Island, Slot].Name]);

      if (Slot = 1) and (Game.Campaign.QuestFlags[Game.Campaign.Island] < 10) then
      begin
        DrawText(true, 25, 240, 'Хозяин Земли');

        if Game.Campaign.Flags.LocalMapOwned[Game.Campaign.Island] then DrawText(false, 2, 256,
    '*) Kаpтa земли куплена')
        else
        begin
          Game.Runtime.AuthorityChange := Game.Campaign.Island * 3000;
          Str(Game.Runtime.AuthorityChange, Text);
          Text := '1) Купить каpту земли ($' + Text + ')';
          DrawText(false, 2, 256, Text);
        end;

        DrawText(false, 2, 264, '2) Визит к хозяину земли');
        DrawText(false, 2, 272, '3) Объявить войну хозяину земли');
        repeat
          Game.Runtime.LastScan := Ord(ReadKey);

          case Game.Runtime.LastScan of
            49: if not PaymentFailed(Game.Campaign.Island * 3000) then
            begin
              Game.Campaign.Flags.LocalMapOwned[Game.Campaign.Island] := true;
              DrawText(false, 2, 256, '*) Kаpтa земли куплена        ');
            end;

            50: Audience;
            51: begin
              Game.Campaign.QuestFlags[Game.Campaign.Island] := 100;
              Game.Runtime.LastScan := 27
            end;
          end;
        until Game.Runtime.LastScan = 27;
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
        Game.Runtime.LastScan := ReadScanCode;
        if Game.Runtime.LastScan = 21 then
          if Game.Campaign.Flags.SiegeEngineOwned then
            if not Game.Campaign.Flags.ArmyAvailable then GameOver
            else SiegeBattle
          else ShowNotice(7);
      end;
    end;
  end;
end;

end.
