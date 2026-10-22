unit KBReport;
{$G+,R-,S-,I+,A+}

interface

uses KBTypes;

procedure ContractReport(Island, Slot: byte);
function ArmyReport(Species: TReportSpecies; Counts: TReportCounts; Caption: string): boolean;
procedure DrawIslandName(Island, X: byte; Y: word);

implementation

uses KBTables, KBUI, KBArt, KBGfx, KBInput, KBFiles, Crt, KBState;

procedure ContractReport(Island, Slot: byte);

const
  Title = 'Контpакт';
  Target = 'Нужно взять замок:';
  Reward = 'Он оценен по контpакту в: $';

var
  Amount: longint;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 240, Title);
  DrawText(false, 2, 256, Target);
  DrawText(false, 21, 256, CastleNames[Game.Campaign.Castles[Island, Slot].Name]);
  Amount := Game.Campaign.Castles[Island, Slot].Value div 100;
  Str(Amount, Game.Runtime.TextBuffer);
  DrawText(false, 2, 272, Reward);
  DrawText(false, 29, 272, Game.Runtime.TextBuffer);
end;

function ArmyReport(Species: TReportSpecies; Counts: TReportCounts; Caption: string): boolean;
label
  Existing, Empty;

const
  FewTroops = ' : Несколько';
  SomeTroops = ' : Немного';
  ManyTroops = ' : Много';
  HordeOfTroops = ' : Толпа';
  ArmyOfTroops = ' : Аpмия';
  JoinOfferCaption = ' ';
  JoinOfferSuffix = ' хотят пpисоединиться к вашему войску.';
  AcceptTroopsPrompt = 'Вы согласны ( Y-да / N-нет ) ?';
  EmptyArmyCaption = 'Войска нет.';

var
  Rows, I: byte;
  UnknownLocal, Quantity: word;

begin
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 2, 240, Caption);
  Rows := 0;
  I := 0;

  repeat
    if Species[I] < 100 then
    begin
      if Counts[I] < 30 then DrawText(false, 12, Rows * 8 + 256, FewTroops)
      else if Counts[I] < 100 then DrawText(false, 12, Rows * 8 + 256, SomeTroops)
      else if Counts[I] < 250 then DrawText(false, 12, Rows * 8 + 256, ManyTroops)
      else if Counts[I] < 500 then DrawText(false, 12, Rows * 8 + 256, HordeOfTroops)
      else DrawText(false, 12, Rows * 8 + 256, ArmyOfTroops);
      DrawText(false, 2, Rows * 8 + 256, CreatureDefinitions[Species[I]].Name);
      Inc(Rows);
    end;

    Inc(I);
  until I > 4;
  if Rows <= 1 then
  begin
    if Caption = JoinOfferCaption then
    begin
      Rows := Random(SummoningSpeciesLimits[Game.Campaign.Island]);
      ArmyReport := true;
      Quantity := Game.Campaign.Leadership div CreatureDefinitions[Rows].Defense;

      if Quantity = 0 then Quantity := 10;
      Caption := CreatureDefinitions[Rows].Name + JoinOfferSuffix;
      DrawText(false, 2, 256, Caption);
      DrawText(false, 15, 304, AcceptTroopsPrompt);
      Game.Runtime.LastScan := ReadScanCode;
      Game.Campaign.Map[Game.Campaign.Island, Game.World.GenerationX, Game.World.GenerationY] := 0;

      if Game.Runtime.LastScan = 21 then
      begin
        for I := 0 to 9 do if Game.Campaign.Army[I].Species = Rows then goto Existing;

        for I := 0 to 9 do if Game.Campaign.Army[I].Species = 100 then goto Empty;
        ShowNotice(6);
        Exit;
Empty:
        Game.Campaign.Flags.ArmyAvailable := true;
        Game.Campaign.Army[I].Species := Rows;
        Game.Campaign.Army[I].Count := Quantity;

        if I < 5 then
        begin
          LoadCreatureArt(Rows);
          CopyRecord(0, I, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
        end;

        Exit;
Existing:
        Inc(Game.Campaign.Army[I].Count, Quantity);
      end;
    end
    else if Rows = 0 then DrawText(false, 25, 256, EmptyArmyCaption);
  end
  else ArmyReport := false;
end;

procedure DrawIslandName(Island, X: byte; Y: word);

const
  Name1 = 'РAВНОЛЕСЬЕ';
  Name2 = 'ЗАБОЛОТИЯ';
  Name3 = 'ТАЙГАНИЯ';
  Name4 = 'АЛЬПИЯ';
  Name5 = 'CАХАРИЯ';

begin
  case Island of
    1: DrawText(false, X, Y, Name1);
    2: DrawText(false, X, Y, Name2);
    3: DrawText(false, X, Y, Name3);
    4: DrawText(false, X, Y, Name4);
    5: DrawText(false, X, Y, Name5);
  end;
end;
end.
