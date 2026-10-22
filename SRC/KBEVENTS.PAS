unit KBEvents;
{$G+,R-,S-,I+,A+}

interface

uses KBTypes, KBState;

procedure BlackMage;

procedure TalkingStoneVisit;

implementation

uses KBFiles, KBUI, KBInput, KBGfx, KBTables, KBBattle, KBWorld, KBAdvent;

type
  TWorkshopState = packed record
    AttackTotal, DefenseTotal: longint;
    Creature: TCreatureDefinition;
    Spells: array[0..7] of byte;
    MutantUsed: array[25..29] of boolean;
    UnknownAfterMutantFlags: byte;
    Number: string[6];
    LastEffect: shortint;
    DonorCursor: byte;
    ArmySlot, NewSpecies, DonorSpecies, Effect, Discount, ArmyCount, Row, Spell, Cursor: byte;
  end;

procedure BlackMage;

const
  MageCaption = 'ЧЕРНЫЙ КОЛДУН';
  PowerLostMessage = 'Уменьшил Вашу волшебную силу.';
  IslandTravelMessage = 'Пеpенес Вас на дpугой континент.';
  TeleportMessage = 'Пеpенес Вас в дpугое место.';
  WorkersLostMessage = 'Забpал Ваших pаботников.';
  GoldLostMessage = 'Забpал Ваше золото.';
  LeadershipLostMessage = 'Уменьшил Ваш автоpитет.';
  ShipSunkMessage = 'Потопил Ваш коpабль.';
  ChartLostMessage = 'Забpал каpту Земли.';
  DiscoveryLostMessage = 'Заставил Вас все забыть.';
  TimeLostMessage = 'Уменьшил отведенное Вам вpемя.';
  ScrollsLostMessage = 'Забpал Ваши волшебства.';
  ArmyLostMessage = 'Забpал Вашу аpмию.';

var
  Event: byte;
  Temporary: word;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(5);
  DrawText(false, 23, 240, MageCaption);
  Event := Random(119) div 10;

  case Event of
    0: DrawText(false, 17, 272, PowerLostMessage);
    1: DrawText(false, 16, 272, IslandTravelMessage);
    2: DrawText(false, 18, 272, TeleportMessage);
    3: DrawText(false, 20, 272, WorkersLostMessage);
    4: DrawText(false, 22, 272, GoldLostMessage);
    5: DrawText(false, 21, 272, LeadershipLostMessage);
    6: DrawText(false, 23, 272, ShipSunkMessage);
    7: DrawText(false, 23, 272, ChartLostMessage);
    8: DrawText(false, 21, 272, DiscoveryLostMessage);
    9: DrawText(false, 20, 272, TimeLostMessage);
    10: DrawText(false, 23, 272, ScrollsLostMessage);
    11: DrawText(false, 25, 272, ArmyLostMessage);
  end;

  case Event of
    0: if Game.MagicPower > 0 then Dec(Game.MagicPower);
    1: begin
      EnterIsland(0);
      RandomHeroLanding
    end;

    2: RandomHeroLanding;
    3: begin
      Game.Carpenters := 0;
      Game.Woodcutters := 0;
      Game.Diggers := 0;
      Game.Stonecutters := 0
    end;

    4: begin
      Game.Gold := 0;
      RefreshGold
    end;

    5: if Game.Leadership > 65535 then Game.Leadership := Random(65535)
      else
      begin
        Temporary := Game.Leadership;
        Game.Leadership := Random(Temporary)
      end;

    6: if Game.ShipOwned then AbandonShip;
    7: Game.LocalMapOwned[Game.Island] := false;
    8: ForgetDiscovery;
    9: begin
      Event := Random(11);
      Game.ExtraDays := 0;

      if Event < Game.Weeks then Dec(Game.Weeks, Event)
      else Game.Weeks := 1;
    end;

    10: for Event := 0 to 13 do Game.Scrolls[Event] := 0;
    11: begin
      for Event := 0 to 9 do Game.Army[Event].Species := 100;
      Game.ArmyAvailable := false;
    end;
  end;

  repeat
    Game.LastScan := ReadScanCode
  until Game.LastScan = 1;
  HeaderPrompt(0);
  byte(Game.MageAge) := Game.Difficulty + 1;
  MoveRoamer(Game.Island, 28, Game.MagePosition);
end;

procedure TalkingStoneVisit;
var
  Event: byte;
  Text: string[50];

procedure TownHint;

const
  TownHintPrefix = 'Нужно найти гоpод ';
  EmptyTownsMessage = 'Здешние гоpода пусты.';

begin
  if Game.Island > 1 then
  begin
    Text := TownHintPrefix + TownNames[Game.Towns[Game.Island, 1].Name];
    DrawText(false, 17, 264, Text);
  end
  else DrawText(false, 19, 264, EmptyTownsMessage);
end;

procedure HiddenSpellHint;

const
  SpellUnavailableMessage = 'Ты не можешь еще владеть заклинаниями.';
  SpellLocationCaption = 'Заклинание спpятано:';
  SpellCoordinatesCaption = 'Континент    X    Y';
  CuckooMessage = 'Ку-ку.';

begin
  if Game.Difficulty = 3 then
  begin
    if Game.MagicPower < 10 then DrawText(false, 13, 264, SpellUnavailableMessage)
    else if Game.HiddenSpellIsland < 100 then
    begin
      DrawText(false, 20, 256, SpellLocationCaption);
      DrawText(false, 20, 272, SpellCoordinatesCaption);
      DrawIslandName(Game.HiddenSpellIsland, 20, 288);
      Inc(Game.InstructionCounter, 2);
      Str(Game.HiddenSpellPosition.X, Game.TextBuffer);
      DrawText(false, 33, 288, Game.TextBuffer);
      Str(Game.HiddenSpellPosition.Y, Game.TextBuffer);
      DrawText(false, 38, 288, Game.TextBuffer);
    end
    else DrawText(false, 27, 264, CuckooMessage);
  end
  else DrawText(false, 27, 264, CuckooMessage);
end;

procedure StoneReport;

const
  StoneCaption = 'ГОВОРЯЩИЙ КАМЕНЬ';
  RitualSpiritMessage = 'Дух РИТУАЛЬНОГО КАМНЯ вызван.';
  GardenMessage = 'Здесь будет гоpод-сад!';
  RestMessage = 'Пpисядь, Рыцаpь, отдохни.';
  UnreadableMessage = 'Надпись неpазбоpчива.';
  ReleaseAnimalsMessage = 'Отпусти животных из своего войска.';
  DoomedPlaceMessage = 'Это гиблое место.';
  PredecessorMessage = 'Здесь покоится Твой пpедшественник.';
  AllegroMessage = 'Вы можете жить на пpоценты: АЛЛЕГРО быстpее инфляции.';
  FindRitualStoneMessage = 'Найди pитуальный камень.';
  StatueMessage = 'I am a fine statue!';
  ComeTomorrowMessage = 'Зайдите завтpа.';

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 22, 240, StoneCaption);

  if (Game.Island = 5) and (Game.SpiritStonePosition.X = Game.GenerationX) and
    (Game.SpiritStonePosition.Y = Game.GenerationY) and Game.SpellAvailable[7] and (Game.Cargo[7] > 99) then
  begin
    DrawText(false, 17, 264, RitualSpiritMessage);
    Game.RitualStoneIsland := 5;
    Game.RitualStonePosition.X := Game.GenerationX;
    Game.RitualStonePosition.Y := Game.GenerationY;
    Game.Cargo[7] := 0;
    Game.LastScan := ReadScanCode;
  end
  else
  begin
    if Game.WorldMapRedraw = 0 then Event := Random(159) div 10
    else Event := Game.InstructionCounter;
    Game.InstructionCounter := Event;
    Game.WorldMapRedraw := 30;

    case Event of
      0: TownHint;
      1: DrawText(false, 19, 264, GardenMessage);
      2: TownHint;
      3: DrawText(false, 18, 264, RestMessage);
      4: TownHint;
      5: DrawText(false, 20, 264, UnreadableMessage);
      6: HiddenSpellHint;
      7: HiddenSpellHint;
      8: DrawText(false, 15, 264, ReleaseAnimalsMessage);
      9: DrawText(false, 21, 264, DoomedPlaceMessage);
      10: HiddenSpellHint;
      11: DrawText(false, 14, 264, PredecessorMessage);
      12: DrawText(false, 5, 264, AllegroMessage);
      13: DrawText(false, 18, 264, FindRitualStoneMessage);
      14: DrawText(false, 20, 264, StatueMessage);
      15: DrawText(false, 22, 264, ComeTomorrowMessage);
    end;

    HeaderPrompt(6);
    Game.LastScan := ReadScanCode;
  end;
end;

procedure Workshop;
var
  WorkshopState: TWorkshopState;

procedure EffectRow(Effect: byte; Selected: boolean);
var
  Cost: byte;

begin
  DrawText(Selected, 7, WorkshopState.Row, Game.SpellTitles[Effect]);
  Cost := RitualCosts[Effect] - WorkshopState.Discount;
  Str(Cost, WorkshopState.Number);
  DrawText(Selected, 49, WorkshopState.Row, WorkshopState.Number);
end;

function PrepareWorkshop: boolean;
label
  FreeSlot, Finished;

var
  I: byte;

begin
  WorkshopState.Discount := 0;
  WorkshopState.Row := 44;
  WorkshopState.LastEffect := -1;
  WorkshopState.ArmyCount := 0;
  Str(Game.RitualPower, WorkshopState.Number);
  DrawText(false, 69, 8, WorkshopState.Number);

  for I := 2 to 5 do
    if Game.Relics[I].Owned then
    begin
      Inc(WorkshopState.Discount);
      DrawPictureTile(WorkshopRelicPositions[I], Game.Relics[I].Artwork);
    end;

  for I := 0 to 4 do
    if Game.Army[I].Species < 100 then
    begin
      Inc(WorkshopState.ArmyCount);
      DrawPictureTile(WorkshopArmyPositions[I], I * 3 + 112);
      ClearPicturePlanes(WorkshopArmyPositions[I], 8);
    end;

  for I := 0 to 6 do
    if Game.SpellAvailable[I] then
    begin
      Inc(WorkshopState.LastEffect);
      WorkshopState.Spells[WorkshopState.LastEffect] := I;
      EffectRow(I, false);
      Inc(WorkshopState.Row, 10);
    end;

  for I := 0 to 9 do
    if Game.Army[I].Species in [25..29] then WorkshopState.MutantUsed[Game.Army[I].Species] := true;
  for I := 25 to 29 do if not WorkshopState.MutantUsed[I] then goto FreeSlot;
  HeaderPrompt(10);
  PrepareWorkshop := false;
  Game.LastScan := ReadScanCode;
  goto Finished;
FreeSlot:
  WorkshopState.NewSpecies := I;
  PrepareWorkshop := true;
  WorkshopState.Creature.Name := CreatureDefinitions[WorkshopState.NewSpecies].Name;
  DrawText(false, 5, 232, CreatureDefinitions[WorkshopState.NewSpecies].Name);
Finished:
end;

procedure SelectEffect;

const
  Caption = 'Выбеpите заклинание и нажмите Enter  Esc-выход';

begin
  WorkshopState.Cursor := 0;
  WorkshopState.Row := 44;
  DrawText(false, 2, 8, Caption);

  repeat
    EffectRow(WorkshopState.Spells[WorkshopState.Cursor], true);
    Game.LastScan := ReadScanCode;
    EffectRow(WorkshopState.Spells[WorkshopState.Cursor], false);

    case Game.LastScan of
      72: if WorkshopState.Cursor > 0 then
      begin
        Dec(WorkshopState.Row, 10);
        Dec(WorkshopState.Cursor)
      end;

      80: if WorkshopState.Cursor < WorkshopState.LastEffect then
      begin
        Inc(WorkshopState.Row, 10);
        Inc(WorkshopState.Cursor)
      end;
    end;
  until (Game.LastScan = 28) or (Game.LastScan = 1);
  EffectRow(WorkshopState.Spells[WorkshopState.Cursor], true);
  WorkshopState.Spell := WorkshopState.Cursor;
  WorkshopState.Effect := WorkshopState.Spells[WorkshopState.Cursor];
end;

procedure DonorReport(Slot: byte);

const
  Blank = '         ';
  YesCaption = ' Да';
  NoCaption = 'Нет';

var
  Flags: byte;

begin
  DrawPictureTile(WorkshopArmyPositions[Slot], Slot * 3 + 112);
  DrawText(false, 43, 232, Blank);
  DrawText(false, 43, 232, CreatureDefinitions[Game.Army[Slot].Species].Name);
  Str(Game.Army[Slot].Count: 6, WorkshopState.Number);
  DrawText(false, 54, 248, WorkshopState.Number);
  Str(CreatureDefinitions[Game.Army[Slot].Species].Movement: 6, WorkshopState.Number);
  DrawText(false, 54, 258, WorkshopState.Number);
  Flags := CreatureDefinitions[Game.Army[Slot].Species].Flags;
  Str((Flags and 96) shr 5: 6, WorkshopState.Number);
  DrawText(false, 54, 268, WorkshopState.Number);
  WorkshopState.AttackTotal := CreatureDefinitions[Game.Army[Slot].Species].Attack;
  WorkshopState.AttackTotal := Game.Army[Slot].Count * WorkshopState.AttackTotal;

  if WorkshopState.AttackTotal >= 1000000 then WorkshopState.AttackTotal := 999999;
  Str(WorkshopState.AttackTotal: 6, WorkshopState.Number);
  DrawText(false, 54, 278, WorkshopState.Number);
  WorkshopState.DefenseTotal := CreatureDefinitions[Game.Army[Slot].Species].Defense;
  WorkshopState.DefenseTotal := Game.Army[Slot].Count * WorkshopState.DefenseTotal;

  if WorkshopState.DefenseTotal >= 1000000 then WorkshopState.DefenseTotal := 999999;
  Str(WorkshopState.DefenseTotal: 6, WorkshopState.Number);
  DrawText(false, 54, 288, WorkshopState.Number);

  if Flags >= 128 then DrawText(false, 57, 298, YesCaption)
  else DrawText(false, 57, 298, NoCaption);
  Flags := Flags and 31;
  Str(Flags: 6, WorkshopState.Number);
  DrawText(false, 54, 308, WorkshopState.Number);
end;

procedure SelectDonor;

const
  Caption = 'Выбеpите воина и нажмите Enter       Esc-выход';

begin
  if (WorkshopState.ArmyCount = 0) or (Game.RitualPower = 0) then Game.LastScan := 2
  else
  begin
    WorkshopState.DonorCursor := 0;
    Game.LastScan := 80;
    DrawText(false, 2, 8, Caption);

    repeat
      if Game.LastScan = 80 then
      begin
        repeat
          while (WorkshopState.DonorCursor < 5)
            and (Game.Army[WorkshopState.DonorCursor].Species = 100) do Inc(WorkshopState.DonorCursor);

          if WorkshopState.DonorCursor = 5 then WorkshopState.DonorCursor := 0;
        until Game.Army[WorkshopState.DonorCursor].Species < 100;
      end
      else
      begin
        repeat
          while (WorkshopState.DonorCursor < 255)
            and (Game.Army[WorkshopState.DonorCursor].Species = 100) do Dec(WorkshopState.DonorCursor);

          if WorkshopState.DonorCursor = 255 then WorkshopState.DonorCursor := 4;
        until Game.Army[WorkshopState.DonorCursor].Species < 100;
      end;

      DonorReport(WorkshopState.DonorCursor);
      Game.LastScan := ReadScanCode;
      ClearPicturePlanes(WorkshopArmyPositions[WorkshopState.DonorCursor], 8);

      case Game.LastScan of
        72: if WorkshopState.DonorCursor > 0 then Dec(WorkshopState.DonorCursor);
        80: if WorkshopState.DonorCursor < 4 then Inc(WorkshopState.DonorCursor);
      end;
    until (Game.LastScan = 28) or (Game.LastScan = 1);

    if Game.LastScan = 1 then Game.LastScan := 2;
  end;
end;

procedure TransferSpecies;
begin
  DrawPictureTile(11385, WorkshopState.DonorCursor * 3 + 112);
  WorkshopState.DonorSpecies := Game.Army[WorkshopState.DonorCursor].Species;
  WorkshopState.ArmySlot := WorkshopState.DonorCursor;
  Str(Game.Army[WorkshopState.DonorCursor].Count: 6, WorkshopState.Number);
  DrawText(false, 17, 248, WorkshopState.Number);
end;

procedure TransferMovement;
begin
  WorkshopState.Creature.Movement := CreatureDefinitions[Game.Army[WorkshopState.DonorCursor].Species].Movement;
  Str(WorkshopState.Creature.Movement: 6, WorkshopState.Number);
  DrawText(false, 17, 258, WorkshopState.Number);
end;

procedure TransferAttack;
begin
  WorkshopState.Creature.Attack := WorkshopState.AttackTotal div Game.Army[WorkshopState.DonorCursor].Count;
  Str(WorkshopState.AttackTotal: 6, WorkshopState.Number);
  DrawText(false, 17, 278, WorkshopState.Number);
end;

procedure TransferDefense;
begin
  WorkshopState.Creature.Defense := WorkshopState.DefenseTotal div Game.Army[WorkshopState.DonorCursor].Count;
  Str(WorkshopState.DefenseTotal: 6, WorkshopState.Number);
  DrawText(false, 17, 288, WorkshopState.Number);
end;

procedure TransferRetaliations;
begin
  WorkshopState.Creature.Flags := WorkshopState.Creature.Flags and 159;
  WorkshopState.Creature.Flags := (CreatureDefinitions[Game.Army[WorkshopState.DonorCursor].Species].Flags and 96)
    or WorkshopState.Creature.Flags;
  Str((WorkshopState.Creature.Flags and 96) shr 5: 6, WorkshopState.Number);
  DrawText(false, 17, 268, WorkshopState.Number);
end;

procedure TransferFlight;
begin
  WorkshopState.Creature.Flags := WorkshopState.Creature.Flags and 127;
  WorkshopState.Creature.Flags := (CreatureDefinitions[Game.Army[WorkshopState.DonorCursor].Species].Flags and 128)
    or WorkshopState.Creature.Flags;

  if WorkshopState.Creature.Flags >= 128 then DrawText(false, 20, 298, ' Да')
  else DrawText(false, 20, 298, 'Нет');
end;

procedure TransferShots;
begin
  WorkshopState.Creature.Flags := WorkshopState.Creature.Flags and 224;
  WorkshopState.Creature.Flags := (CreatureDefinitions[Game.Army[WorkshopState.DonorCursor].Species].Flags and 31)
    or WorkshopState.Creature.Flags;
  Str(WorkshopState.Creature.Flags and 31: 6, WorkshopState.Number);
  DrawText(false, 17, 308, WorkshopState.Number);
end;

procedure ApplyEffect;
label
  ConsumeDonor;

begin
  ClearPicturePlanes(WorkshopArmyPositions[WorkshopState.DonorCursor], 2);
  if Game.RitualPower + WorkshopState.Discount > RitualCosts[WorkshopState.Effect] then
  begin
    Game.RitualPower := Game.RitualPower + WorkshopState.Discount - RitualCosts[WorkshopState.Effect];
    Dec(WorkshopState.ArmyCount);

    if (WorkshopState.DonorSpecies = 100) and (WorkshopState.Effect > 0) then
    begin
      HeaderPrompt(27);
      goto ConsumeDonor
    end;

    case WorkshopState.Effect of
      0: begin
        TransferSpecies;
        TransferMovement;
        TransferAttack;
        TransferDefense;
           TransferRetaliations;
           TransferFlight;
           TransferShots end;
      1: TransferMovement;
      2: TransferAttack;
      3: TransferDefense;
      4: TransferRetaliations;
      5: TransferFlight;
      6: TransferShots;
    end;
  end
  else
  begin
    ClearPicturePlanes(11385, 7);
    Game.RitualPower := 0;
    WorkshopState.DonorSpecies := 100;
  end;

ConsumeDonor:
  Game.Army[WorkshopState.DonorCursor].Species := 100;
  Str(Game.RitualPower: 3, WorkshopState.Number);
  DrawText(false, 69, 8, WorkshopState.Number);
end;

begin
  if (Game.Difficulty = 3) and (Game.MagicPower > 9) then
  begin
    FillChar(WorkshopState.MutantUsed, 5, 0);
    WorkshopState.DonorSpecies := 100;
    Game.PicturePage := 32768;
    Game.PictureFileName := 'CHARM.PIC';
    LoadScreenPicture;
    SetVideoPage(1);

    if CountRitualSpells = 0 then
    begin
      HeaderPrompt(11);
      Game.LastScan := ReadScanCode
    end
    else if not PrepareWorkshop then
    begin
      HeaderPrompt(10);
      Game.LastScan := ReadScanCode
    end
    else if WorkshopState.ArmyCount = 0 then
    begin
      HeaderPrompt(26);
      Game.LastScan := ReadScanCode
    end
    else
    begin
      repeat
        SelectEffect;

        if Game.LastScan = 28 then SelectDonor;
        if Game.LastScan = 28 then ApplyEffect;
        EffectRow(WorkshopState.Spells[WorkshopState.Spell], false);
      until Game.LastScan = 1;

      if WorkshopState.DonorSpecies < 100 then
      begin
        StoreMutantFrames(WorkshopState.NewSpecies - 25, WorkshopState.ArmySlot * 3);
        CreatureDefinitions[WorkshopState.NewSpecies] := WorkshopState.Creature;
        CreatureDefinitions[WorkshopState.NewSpecies].Cost.Price := 0;
        Game.Army[WorkshopState.ArmySlot].Species := WorkshopState.NewSpecies;
        CreatureDefinitions[WorkshopState.NewSpecies].Cost.Price := WorkshopState.DonorSpecies;
        CreatureDefinitions[WorkshopState.NewSpecies].Cost.Price := CreatureDefinitions[WorkshopState.NewSpecies].
          Cost.Price shl 8;
        CreatureDefinitions[WorkshopState.NewSpecies].Cost.Price := CreatureDefinitions[WorkshopState.NewSpecies].
          Cost.Price or Game.RitualPower;
      end;
    end;

    SetVideoPage(0);
    Game.PictureFileName := 'STATUS.PIC';
    LoadScreenPicture;
    LoadResourceFile(Game.PictureBanks[4], Game.IslandPictureFileName);
    Game.TownPictureLoaded := false;
    Game.PicturePage := 0;
  end
  else
  begin
    DrawDialog(8, 230, 488, 320);
    DrawText(false, 22, 240, 'РИТУАЛЬНЫЙ КАМЕНЬ');
    DrawText(false, 6, 256, 'Став более искусным Магом, Ты обpетешь новое качество.');
    Game.LastScan := ReadScanCode;
  end;
end;

begin
  if (Game.Island = Game.RitualStoneIsland) and (Game.GenerationX = Game.RitualStonePosition.X)
    and (Game.GenerationY = Game.RitualStonePosition.Y) then
    if (Game.Hero.X = Game.GenerationX) and (Game.Hero.Y = Game.GenerationY + 1) then Workshop
    else StoneReport
  else StoneReport;
  HeaderPrompt(0);
end;

begin
end.
