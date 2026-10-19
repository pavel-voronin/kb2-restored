procedure ArmyOverview;

procedure DrawOverview;
var
  I, Row: byte;
  Total: longint;

begin
  Row := 0;
  ClearRectangle(8, 22, 488, 321);

  for I := 0 to 4 do
    if Game.Army[I].Species < 100 then
    begin
      DrawTile(BattleCellOffsets[Row * 6], 0, I * 3 + 112);
      Str(Game.Army[I].Count, Game.TextBuffer);
      Game.AuthorityChange := Row * 60 + 32;
      DrawLine(104, Row * 60 + 81, 487, Row * 60 + 81, 15);
      DrawText(false, 15, Game.AuthorityChange, CreatureDefinitions[Game.Army[I].Species].Name);
      DrawText(false, 25, Game.AuthorityChange, Game.TextBuffer);
      Total := Game.Army[I].Count;
      Str(Total * CreatureDefinitions[Game.Army[I].Species].Attack, Game.TextBuffer);
      Game.TextBuffer := '“¤ p  :' + Game.TextBuffer;
      DrawText(false, 30, Game.AuthorityChange + 16, Game.TextBuffer);
      Str(Total * CreatureDefinitions[Game.Army[I].Species].Defense, Game.TextBuffer);
      Game.TextBuffer := '‡ é¨â :' + Game.TextBuffer;
      DrawText(false, 30, Game.AuthorityChange + 24, Game.TextBuffer);

      if Game.Army[I].Species > 24 then
      begin
        Str(CreatureDefinitions[Game.Army[I].Species].Cost.Price and 255, Game.TextBuffer);
        Game.TextBuffer := '¥¤¥«¨: ' + Game.TextBuffer;
        DrawText(false, 40, Game.AuthorityChange + 40, Game.TextBuffer);
      end
      else
      begin
        Total := (Game.Leadership + Game.LeadershipBonus) div CreatureDefinitions[Game.Army[I].Species].Defense;

        if Game.Army[I].Count > Total then DrawText(true, 15, Game.AuthorityChange + 40, '‚ëè«¨ ¨§ ¯®¤ ª®­âp®«ï')
        else DrawText(false, 15, Game.AuthorityChange + 40, 'Š®­âp®«¨pãîâáï');
      end;

      Inc(Row);
    end;

  DrawText(true, 30, 24, '…‚‰ €‘—…’');
end;

procedure ToggleArrangement;
begin
  Game.ArrangementReserve := not Game.ArrangementReserve;
  DrawArmyCaption(Game.ArrangementReserve, 240, '…‚‰ …‡…‚');
end;

procedure DrawArrangement;
var
  I: byte;

begin
  Game.ArrangementCount := 0;
  DrawDialog(8, 230, 488, 320);
  DrawText(false, 30, 24, '…‚‰ €‘—…’');
  ToggleArrangement;

  for I := 0 to 4 do
    if Game.Army[I].Species < 100 then
    begin
      Inc(Game.ArrangementCount);
      Game.ActiveArmyRows[Game.ArrangementCount] := I;
      Game.AuthorityChange := Game.ArrangementCount * 8 + 248;
      Str(Game.ArrangementCount, Game.TextBuffer);
      Game.ArrangementText := Game.TextBuffer + ') ' + CreatureDefinitions[Game.Army[I].Species].Name;
      DrawText(false, 3, Game.AuthorityChange, Game.ArrangementText);
      Str(Game.Army[I].Count, Game.TextBuffer);
      DrawText(false, 16, Game.AuthorityChange, Game.TextBuffer);
    end;

  Game.ArrangementCount := 0;
  for I := 5 to 9 do
    if Game.Army[I].Species < 100 then
    begin
      Inc(Game.ArrangementCount);
      Game.ReserveArmyRows[Game.ArrangementCount] := I;
      Game.AuthorityChange := Game.ArrangementCount * 8 + 248;
      Str(Game.ArrangementCount, Game.TextBuffer);
      Game.ArrangementText := Game.TextBuffer + ') ' + CreatureDefinitions[Game.Army[I].Species].Name;
      DrawText(false, 42, Game.AuthorityChange, Game.ArrangementText);
      Str(Game.Army[I].Count, Game.TextBuffer);
      DrawText(false, 55, Game.AuthorityChange, Game.TextBuffer);
    end;

  if Game.ArrangementOverflow.Species < 100 then
  begin
    Game.ArrangementText := '6) ' + CreatureDefinitions[Game.ArrangementOverflow.Species].Name;
    DrawText(false, 42, 296, Game.ArrangementText);
    Str(Game.ArrangementOverflow.Count, Game.TextBuffer);
    DrawText(false, 55, 296, Game.TextBuffer);
  end;
end;

procedure TransferArrangement;
label
  Finished, ActiveFree, ReserveFree, Redraw;

var
  I: byte;

begin
  Val(Chr(Game.LastScan), Game.ArrangementCount, Game.AuthorityChange);
  if Game.ArrangementReserve then
  begin
    if Game.ArrangementCount = 6 then
    begin
      if Game.ArrangementOverflow.Species = 100 then
      begin
        ShowNotice(12);
        DrawArrangement;
        goto Finished;
      end;
    end
    else if Game.Army[Game.ReserveArmyRows[Game.ArrangementCount]].Species = 100 then
    begin
      ShowNotice(12);
      DrawArrangement;
      goto Finished;
    end;

    for I := 0 to 4 do if Game.Army[I].Species = 100 then goto ActiveFree;
    ShowNotice(10);
    DrawArrangement;
    goto Finished;
ActiveFree:
    Game.Army[I] := Game.Army[Game.ReserveArmyRows[Game.ArrangementCount]];

    if Game.ArrangementOverflow.Species < 100 then
    begin
      Game.Army[Game.ReserveArmyRows[Game.ArrangementCount]] := Game.ArrangementOverflow;
      Game.ArrangementOverflow.Species := 100;
    end
    else Game.Army[Game.ReserveArmyRows[Game.ArrangementCount]].Species := 100;
  end
  else
  begin
    if Game.Army[Game.ActiveArmyRows[Game.ArrangementCount]].Species = 100 then
    begin
      ShowNotice(12);
      DrawArrangement;
      goto Finished;
    end;

    for I := 5 to 9 do if Game.Army[I].Species = 100 then goto ReserveFree;
    if Game.ArrangementOverflow.Species < 100 then
    begin
      ShowNotice(11);
      DrawArrangement;
      goto Finished;
    end
    else
    begin
      Game.ArrangementOverflow := Game.Army[Game.ActiveArmyRows[Game.ArrangementCount]];
      Game.Army[Game.ActiveArmyRows[Game.ArrangementCount]].Species := 100;
    end;

    goto Redraw;
ReserveFree:
    Game.Army[I] := Game.Army[Game.ActiveArmyRows[Game.ArrangementCount]];
    Game.Army[Game.ActiveArmyRows[Game.ArrangementCount]].Species := 100;
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
  FillChar(Game.ArrangementOverflow, 3, 100);
  FillChar(Game.ReserveArmyRows, 5, 0);
  FillChar(Game.ActiveArmyRows, 5, 0);

  for I := 0 to 4 do Game.ArrangementOriginal[I] := Game.Army[I];
  DrawArrangement;
  repeat
    Game.LastScan := Ord(ReadKey);

    case Game.LastScan of
      9: ToggleArrangement;
      49..54: TransferArrangement;
    end;
  until Game.LastScan = 27;

  for I := 0 to 4 do
    if (Game.ArrangementOriginal[I].Species <> Game.Army[I].Species) and (Game.Army[I].Species < 100) then
    begin
      LoadCreatureArt(Game.Army[I].Species);
      CopyRecord(0, I, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
    end;

  DrawOverview;
  Game.LastScan := 48;
end;

begin
  Game.ArrangementReserve := true;
  if Game.ArmyAvailable then
  begin
    DrawOverview;

    repeat
      HeaderPrompt(23);
      Game.LastScan := Ord(ReadKey);

      if Game.LastScan = 9 then ArrangeArmy;
    until Game.LastScan = 27;
  end
  else
  begin
    ClearRectangle(8, 22, 488, 321);
    HeaderPrompt(6);
    DrawText(false, 23, 150, '‚‰‘Š ’‘“’‘’‚“…’ !');
    Game.LastScan := Ord(ReadKey);
  end;

  HeaderPrompt(0);
end;
