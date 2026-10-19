procedure WorkersMenu(Island: byte);
var
  Number: string[2];

procedure EditTerrain(var Stock: word; Base, Span, Replacement: byte);
var
  UnknownLocal: word;
  X, Y, Tile: byte;

begin
  HeaderPrompt(1);
  DrawAdventureField;
  Game.LastScan := Ord(ReadKey);

  case Game.LastScan of
    0: begin
      Game.LastScan := Ord(ReadKey);

      case Game.LastScan of
        72, 75, 77, 80:
          if (Game.Map[Island, Game.Hero.X + WorkerDirections[Game.LastScan].X,
            Game.Hero.Y + WorkerDirections[Game.LastScan].Y] >= Base)
            and (Game.Map[Island, Game.Hero.X + WorkerDirections[Game.LastScan].X,
              Game.Hero.Y + WorkerDirections[Game.LastScan].Y] < Base + Span)
          then
          begin
            X := Game.Hero.X + WorkerDirections[Game.LastScan].X;
            Y := Game.Hero.Y + WorkerDirections[Game.LastScan].Y;
            Tile := Replacement;

            if (Island = 5) and (Base = 80) and (Game.RegrowthPosition.X = 100) then
            begin
              Game.RegrowthPosition.X := X;
              Game.RegrowthPosition.Y := Y;
              Game.RegrowthCountdown := 6;
            end;

            if Replacement = 0 then
            begin
              if (Game.Map[Island, X, Y - 1] >= Base)
                and (Game.Map[Island, X, Y - 1] < Base + Span) then
                Dec(Game.Map[Island, X, Y - 1], 2);
              if (Game.Map[Island, X, Y + 1] >= Base)
                and (Game.Map[Island, X, Y + 1] < Base + Span) then
                Dec(Game.Map[Island, X, Y + 1], 1);
              if (Game.Map[Island, X - 1, Y] >= Base)
                and (Game.Map[Island, X - 1, Y] < Base + Span) then
                Dec(Game.Map[Island, X - 1, Y], 8);
              if (Game.Map[Island, X + 1, Y] >= Base)
                and (Game.Map[Island, X + 1, Y] < Base + Span) then
                Dec(Game.Map[Island, X + 1, Y], 4);
            end;

            if Replacement = 48 then
            begin
              if (Game.Map[Island, X, Y - 1] >= Replacement)
                and (Game.Map[Island, X, Y - 1] < Replacement + 16) then
              begin
                Tile := Tile + 1;
                Game.Map[Island, X, Y - 1] := Game.Map[Island, X, Y - 1] + 2;
              end;

              if (Game.Map[Island, X, Y + 1] >= Replacement)
                and (Game.Map[Island, X, Y + 1] < Replacement + 16) then
              begin
                Tile := Tile + 2;
                Game.Map[Island, X, Y + 1] := Game.Map[Island, X, Y + 1] + 1;
              end;

              if (Game.Map[Island, X - 1, Y] >= Replacement)
                and (Game.Map[Island, X - 1, Y] < Replacement + 16) then
              begin
                Tile := Tile + 4;
                Game.Map[Island, X - 1, Y] := Game.Map[Island, X - 1, Y] + 8;
              end;

              if (Game.Map[Island, X + 1, Y] >= Replacement)
                and (Game.Map[Island, X + 1, Y] < Replacement + 16) then
              begin
                Tile := Tile + 8;
                Game.Map[Island, X + 1, Y] := Game.Map[Island, X + 1, Y] + 4;
              end;
            end;

            Game.Map[Island, X, Y] := Tile;
            Dec(Stock);
          end;
      end;
    end;
  end;

  HeaderPrompt(0);
end;

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(29);
  DrawText(false, 2, 240, '€Ž’ˆŠˆ');
  DrawText(false, 2, 256, '1) «®â­¨ª¨ :');
  Str(Game.Carpenters, Number);
  DrawText(false, 16, 256, Number);
  DrawText(false, 2, 264, '2) ‹¥á®pã¡ë :');
  Str(Game.Woodcutters, Number);
  DrawText(false, 16, 264, Number);
  DrawText(false, 2, 272, '3) ‡¥¬«¥ª®¯ë:');
  Str(Game.Diggers, Number);
  DrawText(false, 16, 272, Number);
  DrawText(false, 2, 280, '4) Š ¬­¥â¥áë:');
  Str(Game.Stonecutters, Number);
  DrawText(false, 16, 280, Number);
  Game.LastScan := Ord(ReadKey);

  case Game.LastScan of
    49: if Game.Carpenters > 0 then EditTerrain(Game.Carpenters, 32, 32, 4)
    else HeaderPrompt(8);
    50: if Game.Woodcutters > 0 then EditTerrain(Game.Woodcutters, 64, 16, 0)
    else HeaderPrompt(8);
    51: if Game.Diggers > 0 then EditTerrain(Game.Diggers, 0, 1, 48)
    else HeaderPrompt(8);
    52: if Game.Stonecutters > 0 then EditTerrain(Game.Stonecutters, 80, 16, 0)
    else HeaderPrompt(8);
  else Game.LastScan := 48;
  end;
end;
