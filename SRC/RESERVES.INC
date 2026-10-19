procedure ReserveMenu;

const
  ReserveCaption = #129#142#133#130#142#137' '#144#133#135#133#144#130;
  ListSuffix = ') ';

var
  ReserveState: TReserveState;

procedure DrawReserve;
var
  I: byte;

begin
  DrawDialog(8, 230, 584, 320);
  DrawArmyCaption(ReserveState.ReserveMode, 240, ReserveCaption);
  ReserveState.Count := 0;

  for I := 0 to 4 do
    if Game.BattleField[0, I] > 111 then
    begin
      Inc(ReserveState.Count);
      ReserveState.ActiveSlots[ReserveState.Count] := (Game.BattleField[0, I] - 112) div 3;
      Game.BattleTextColumn := ReserveState.Count * 8 + 248;
      Str(ReserveState.Count, ReserveState.Text);
      ReserveState.Text := ReserveState.Text + ListSuffix +
        CreatureDefinitions[Combat.Player[ReserveState.ActiveSlots[ReserveState.Count]].Species].Name;
      DrawText(false, 3, Game.BattleTextColumn, ReserveState.Text);
      Str(Combat.Player[ReserveState.ActiveSlots[ReserveState.Count]].Count, Game.TextBuffer);
      DrawText(false, 16, Game.BattleTextColumn, Game.TextBuffer);
    end;

  ReserveState.Count := 0;
  for I := 5 to 9 do
    if Combat.Player[I].Species < 100 then
    begin
      Inc(ReserveState.Count);
      ReserveState.ReserveSlots[ReserveState.Count] := I;
      Game.BattleTextColumn := ReserveState.Count * 8 + 248;
      Str(ReserveState.Count, ReserveState.Text);
      ReserveState.Text := ReserveState.Text + ListSuffix + CreatureDefinitions[Combat.Player[I].Species].Name;
      DrawText(false, 42, Game.BattleTextColumn, ReserveState.Text);
      Str(Combat.Player[I].Count, Game.TextBuffer);
      DrawText(false, 55, Game.BattleTextColumn, Game.TextBuffer);
    end;
end;

procedure ChangeReserve;
label
  Finished;

var
  Y, Slot: byte;

begin
  Val(Chr(Game.LastScan), ReserveState.Count, Game.BattleTextColumn);
  if ReserveState.ReserveMode then
  begin
    if Combat.Player[ReserveState.ReserveSlots[ReserveState.Count]].Species < 100 then
      for Slot := 0 to 4 do
        if Combat.Player[Slot].Species = 100 then
        begin
          Y := 0;

          while (Y < 5) and (Game.BattleField[0, Y] > 0) do Inc(Y);
          if Y = 5 then goto Finished;
          Combat.Player[Slot] := Combat.Player[ReserveState.ReserveSlots[ReserveState.Count]];
          Game.BattleField[0, Y] := Slot * 3 + 112;
          Game.BattleDistances[0, Y] := Combat.Player[Slot].Count;
          Combat.Player[ReserveState.ReserveSlots[ReserveState.Count]].Species := 100;
          Inc(Combat.PlayerCount);
          goto Finished;
        end;
  end
  else
  begin
    if Combat.Player[ReserveState.ActiveSlots[ReserveState.Count]].Species < 100 then
      for Slot := 5 to 9 do
        if Combat.Player[Slot].Species = 100 then
        begin
          FindUnitCell(ReserveState.ActiveSlots[ReserveState.Count], 112, ReserveState.FieldX, Y);
          Game.BattleField[ReserveState.FieldX, Y] := 0;
          Game.BattleDistances[ReserveState.FieldX, Y] := 0;
          Combat.Player[Slot] := Combat.Player[ReserveState.ActiveSlots[ReserveState.Count]];
          Combat.Player[ReserveState.ActiveSlots[ReserveState.Count]].Species := 100;
          Dec(Combat.PlayerCount);
          goto Finished;
        end;
  end;

Finished:
  DrawReserve;
end;

procedure RebuildReserve;
var
  X, Y: byte;

begin
  Combat.PlayerCount := 0;
  for X := 0 to 5 do
    for Y := 0 to 4 do
      if Game.BattleField[X, Y] > 111 then
      begin
        Inc(Combat.PlayerCount);

        if X = 0 then
        begin
          ReserveState.Selected := (Game.BattleField[X, Y] - 112) div 3;
          LoadCreatureArt(Combat.Player[ReserveState.Selected].Species);
          CopyRecord(0, ReserveState.Selected, 8640, Game.PictureBanks[11], Game.PictureBanks[10]);
          DrawTile(BattleCellOffsets[Y * 6 + 0], 0, Game.BattleField[0, Y]);
          DrawCellCount(0, Y);
        end;
      end
      else
        if (X = 0) and (Game.BattleField[0, Y] = 0) then
          DrawPictureTile(BattleCellOffsets[Y * 6], 0);
  if Combat.PlayerCount = 0 then Game.BattleResult := 2;
end;

begin
  ReserveState.ReserveMode := false;
  DrawReserve;
  HeaderPrompt(24);

  repeat
    Game.LastScan := Ord(ReadKey);
    case Game.LastScan of
      9: begin
        ReserveState.ReserveMode := not ReserveState.ReserveMode;
        DrawArmyCaption(ReserveState.ReserveMode, 240, ReserveCaption);
      end;

      49..53: ChangeReserve;
    end;
  until Game.LastScan = 27;
  Game.LastScan := 49;
  RebuildReserve;
  RedrawLowerRows;
end;

procedure CheckLeadership;
label
  Next;

var
  Slot: byte;

begin
  Combat.PlayerCount := 0;
  for Slot := 0 to 4 do
    if Combat.Player[Slot].Species < 100 then
    begin
      if Combat.Player[Slot].Species < 25 then
      begin
        Combat.LeadershipLimit := (Game.Leadership + Game.LeadershipBonus) div
          CreatureDefinitions[Combat.Player[Slot].Species].Defense;
        if Combat.Player[Slot].Count > Combat.LeadershipLimit then
        begin
          Combat.Uncontrolled[Slot] := true;
          goto Next;
        end;
      end;

      Combat.Uncontrolled[Slot] := false;
      Inc(Combat.PlayerCount);
Next:
    end;
end;

procedure UncontrolledTurn;
label
  Attack, Next, Direction, Step;

const
  Caption = 'Воины вышли из под контpоля.';

var
  I: byte;
  TX, TY: shortint;
  Slot, X, Y, Movement: byte;

begin
  for Slot := 0 to 4 do
  begin
    if (Combat.Player[Slot].Species < 100) and Combat.Uncontrolled[Slot] then
    begin
        DrawText(false, 2, 8, Caption);
        Combat.CanMove[Slot] := false;
        Movement := CreatureDefinitions[Combat.Player[Slot].Species].Movement;
        FindUnitCell(Slot, 112, X, Y);
Step:
          TX := X;
          TY := Y;

          if FindAdjacent(TX, TY, 111) then goto Attack;
          TX := X;
          TY := Y;

          if FindAdjacent(TX, TY, 31) then goto Attack;
          TX := Random(10);
          Game.StepX := 1;
          Game.StepY := 1;
Direction:
          Inc(TX);

          case TX of
            0: begin
              Game.StepX := -1;
              Game.StepY := -1
            end;

            1: begin
              Game.StepX := 0;
              Game.StepY := -1
            end;

            2: begin
              Game.StepX := 1;
              Game.StepY := -1
            end;

            3: begin
              Game.StepX := 1;
              Game.StepY := 0
            end;

            4: begin
              Game.StepX := 1;
              Game.StepY := 1
            end;

            5: begin
              Game.StepX := 0;
              Game.StepY := 1
            end;

            6: begin
              Game.StepX := -1;
              Game.StepY := 1
            end;

            7: begin
              Game.StepX := -1;
              Game.StepY := 0
            end;
          else TX := 0;
          end;

          if X + Game.StepX < 0 then goto Direction;
          if Y + Game.StepY < 0 then goto Direction;
          if X + Game.StepX >= 6 then goto Direction;

          if Y + Game.StepY >= 5 then goto Direction;
          if Game.BattleField[X + Game.StepX, Y + Game.StepY] <> 0 then goto Direction;
          TX := X + Game.StepX;
          TY := Y + Game.StepY;
          Dec(Movement);

          for I := 1 to 6 do PulseCell(X, Y, I);
          RelocateUnit(X, Y, TX, TY);
        if Movement > 0 then goto Step
        else goto Next;
    end
    else goto Next;
Attack:
        for I := 1 to 6 do PulseCell(X, Y, I);
        AttackUnit(X, Y, TX, TY);

        if Game.BattleDistances[TX, TY] > 0 then AttackUnit(TX, TY, X, Y);
Next:
      end;

  Combat.RoundMagicReady := false;
end;

procedure MarkPlayerUnits;
var
  Slot, X, Y: byte;

begin
  for Slot := 0 to 4 do
    if Combat.Player[Slot].Species < 100 then
    begin
      FindUnitCell(Slot, 112, X, Y);
      DrawMaskedTile(BattleCellOffsets[Y * 6 + X], Game.BattleField[X, Y], 8);
    end;
end;
