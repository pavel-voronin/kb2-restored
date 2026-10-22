unit KBArmy;
{$G+,R-,S-,I+,A+}

interface

procedure ArmyOverview;

implementation

uses KBTables, KBUI, KBArt, KBGfx, KBFiles, Crt, KBState;

procedure ArmyOverview;

procedure DrawOverview;
var
  I, Row: byte;
  Total: longint;

begin
  Row := 0;
  ClearRectangle(8, 22, 488, 321);

  for I := 0 to 4 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      DrawTile(BattleCellOffsets[Row * 6], 0, I * 3 + 112);
      Str(Game.Campaign.Army[I].Count, Game.Runtime.TextBuffer);
      Game.Runtime.AuthorityChange := Row * 60 + 32;
      DrawLine(104, Row * 60 + 81, 487, Row * 60 + 81, 15);
      DrawText(false, 15, Game.Runtime.AuthorityChange, CreatureDefinitions[Game.Campaign.Army[I].Species].Name);
      DrawText(false, 25, Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
      Total := Game.Campaign.Army[I].Count;
      Str(Total * CreatureDefinitions[Game.Campaign.Army[I].Species].Attack, Game.Runtime.TextBuffer);
      Game.Runtime.TextBuffer := '“¤ p  :' + Game.Runtime.TextBuffer;
      DrawText(false, 30, Game.Runtime.AuthorityChange + 16, Game.Runtime.TextBuffer);
      Str(Total * CreatureDefinitions[Game.Campaign.Army[I].Species].Defense, Game.Runtime.TextBuffer);
      Game.Runtime.TextBuffer := '‡ é¨â :' + Game.Runtime.TextBuffer;
      DrawText(false, 30, Game.Runtime.AuthorityChange + 24, Game.Runtime.TextBuffer);

      if Game.Campaign.Army[I].Species > 24 then
      begin
        Str(CreatureDefinitions[Game.Campaign.Army[I].Species].Cost.Price and 255, Game.Runtime.TextBuffer);
        Game.Runtime.TextBuffer := '¥¤¥«¨: ' + Game.Runtime.TextBuffer;
        DrawText(false, 40, Game.Runtime.AuthorityChange + 40, Game.Runtime.TextBuffer);
      end
      else
      begin
        Total := (Game.Campaign.Leadership + Game.Campaign.LeadershipBonus) div
    CreatureDefinitions[Game.Campaign.Army[I].Species].Defense;

        if Game.Campaign.Army[I].Count > Total then DrawText(true, 15, Game.Runtime.AuthorityChange + 40,
    '‚ëè«¨ ¨§ ¯®¤ ª®­âp®«ï')
        else DrawText(false, 15, Game.Runtime.AuthorityChange + 40, 'Š®­âp®«¨pãîâáï');
      end;

      Inc(Row);
    end;

  DrawText(true, 30, 24, '…‚‰ €‘—…’');
end;

procedure ToggleArrangement;
begin
  Game.Runtime.ArrangementReserve := not Game.Runtime.ArrangementReserve;
  DrawArmyCaption(Game.Runtime.ArrangementReserve, 240, '…‚‰ …‡…‚');
end;

procedure DrawArrangement;
var
  I: byte;

begin
  Game.Runtime.ArrangementCount := 0;
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 30, 24, '…‚‰ €‘—…’');
  ToggleArrangement;

  for I := 0 to 4 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      Inc(Game.Runtime.ArrangementCount);
      Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount] := I;
      Game.Runtime.AuthorityChange := Game.Runtime.ArrangementCount * 8 + 248;
      Str(Game.Runtime.ArrangementCount, Game.Runtime.TextBuffer);
      Game.Runtime.ArrangementText := Game.Runtime.TextBuffer + ') ' +
    CreatureDefinitions[Game.Campaign.Army[I].Species].Name;
      DrawText(false, 3, Game.Runtime.AuthorityChange, Game.Runtime.ArrangementText);
      Str(Game.Campaign.Army[I].Count, Game.Runtime.TextBuffer);
      DrawText(false, 16, Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
    end;

  Game.Runtime.ArrangementCount := 0;
  for I := 5 to 9 do
    if Game.Campaign.Army[I].Species < 100 then
    begin
      Inc(Game.Runtime.ArrangementCount);
      Game.Runtime.ReserveArmyRows[Game.Runtime.ArrangementCount] := I;
      Game.Runtime.AuthorityChange := Game.Runtime.ArrangementCount * 8 + 248;
      Str(Game.Runtime.ArrangementCount, Game.Runtime.TextBuffer);
      Game.Runtime.ArrangementText := Game.Runtime.TextBuffer + ') ' +
    CreatureDefinitions[Game.Campaign.Army[I].Species].Name;
      DrawText(false, 42, Game.Runtime.AuthorityChange, Game.Runtime.ArrangementText);
      Str(Game.Campaign.Army[I].Count, Game.Runtime.TextBuffer);
      DrawText(false, 55, Game.Runtime.AuthorityChange, Game.Runtime.TextBuffer);
    end;

  if Game.Runtime.ArrangementOverflow.Species < 100 then
  begin
    Game.Runtime.ArrangementText := '6) ' + CreatureDefinitions[Game.Runtime.ArrangementOverflow.Species].Name;
    DrawText(false, 42, 296, Game.Runtime.ArrangementText);
    Str(Game.Runtime.ArrangementOverflow.Count, Game.Runtime.TextBuffer);
    DrawText(false, 55, 296, Game.Runtime.TextBuffer);
  end;
end;

procedure TransferArrangement;
label
  Finished, ActiveFree, ReserveFree, Redraw;

var
  I: byte;

begin
  Val(Chr(Game.Runtime.LastScan), Game.Runtime.ArrangementCount, Game.Runtime.AuthorityChange);
  if Game.Runtime.ArrangementReserve then
  begin
    if Game.Runtime.ArrangementCount = 6 then
    begin
      if Game.Runtime.ArrangementOverflow.Species = 100 then
      begin
        ShowNotice(12);
        DrawArrangement;
        goto Finished;
      end;
    end
    else if Game.Campaign.Army[Game.Runtime.ReserveArmyRows[Game.Runtime.ArrangementCount]].Species = 100 then
    begin
      ShowNotice(12);
      DrawArrangement;
      goto Finished;
    end;

    for I := 0 to 4 do if Game.Campaign.Army[I].Species = 100 then goto ActiveFree;
    ShowNotice(10);
    DrawArrangement;
    goto Finished;
ActiveFree:
    Game.Campaign.Army[I] := Game.Campaign.Army[Game.Runtime.ReserveArmyRows[Game.Runtime.ArrangementCount]];

    if Game.Runtime.ArrangementOverflow.Species < 100 then
    begin
      Game.Campaign.Army[Game.Runtime.ReserveArmyRows[Game.Runtime.ArrangementCount]] :=
    Game.Runtime.ArrangementOverflow;
      Game.Runtime.ArrangementOverflow.Species := 100;
    end
    else Game.Campaign.Army[Game.Runtime.ReserveArmyRows[Game.Runtime.ArrangementCount]].Species := 100;
  end
  else
  begin
    if Game.Campaign.Army[Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount]].Species = 100 then
    begin
      ShowNotice(12);
      DrawArrangement;
      goto Finished;
    end;

    for I := 5 to 9 do if Game.Campaign.Army[I].Species = 100 then goto ReserveFree;
    if Game.Runtime.ArrangementOverflow.Species < 100 then
    begin
      ShowNotice(11);
      DrawArrangement;
      goto Finished;
    end
    else
    begin
      Game.Runtime.ArrangementOverflow :=
    Game.Campaign.Army[Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount]];
      Game.Campaign.Army[Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount]].Species := 100;
    end;

    goto Redraw;
ReserveFree:
    Game.Campaign.Army[I] := Game.Campaign.Army[Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount]];
    Game.Campaign.Army[Game.Runtime.ActiveArmyRows[Game.Runtime.ArrangementCount]].Species := 100;
  end;

Redraw:
  DrawArrangement;
Finished:
end;

procedure ArrangeArmy;
var
  I: byte;

begin
  HeaderPrompt(24);
  FillChar(Game.Runtime.ArrangementOverflow, 3, 100);
  FillChar(Game.Runtime.ReserveArmyRows, 5, 0);
  FillChar(Game.Runtime.ActiveArmyRows, 5, 0);

  for I := 0 to 4 do Game.Runtime.ArrangementOriginal[I] := Game.Campaign.Army[I];
  DrawArrangement;
  repeat
    Game.Runtime.LastScan := Ord(ReadKey);

    case Game.Runtime.LastScan of
      9: ToggleArrangement;
      49..54: TransferArrangement;
    end;
  until Game.Runtime.LastScan = 27;

  for I := 0 to 4 do
    if (Game.Runtime.ArrangementOriginal[I].Species <> Game.Campaign.Army[I].Species) and
    (Game.Campaign.Army[I].Species < 100) then
    begin
      LoadCreatureArt(Game.Campaign.Army[I].Species);
      CopyRecord(0, I, 8640, Game.Runtime.PictureBanks[11], Game.Runtime.PictureBanks[10]);
    end;

  DrawOverview;
  Game.Runtime.LastScan := 48;
end;

begin
  Game.Runtime.ArrangementReserve := true;
  if Game.Campaign.Flags.ArmyAvailable then
  begin
    DrawOverview;

    repeat
      HeaderPrompt(23);
      Game.Runtime.LastScan := Ord(ReadKey);

      if Game.Runtime.LastScan = 9 then ArrangeArmy;
    until Game.Runtime.LastScan = 27;
  end
  else
  begin
    ClearRectangle(8, 22, 488, 321);
    HeaderPrompt(6);
    DrawText(false, 23, 150, '‚‰‘Š ’‘“’‘’‚“…’ !');
    Game.Runtime.LastScan := Ord(ReadKey);
  end;

  HeaderPrompt(0);
end;

end.
