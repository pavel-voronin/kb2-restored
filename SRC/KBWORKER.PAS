unit KBWorker;
{$G+,R-,S-,I+,A+}

interface

procedure WorkersMenu(Island: byte);

implementation

uses KBState, KBTables, KBUI, KBView, KBGfx, Crt;

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
  Game.Runtime.LastScan := Ord(ReadKey);

  case Game.Runtime.LastScan of
    0: begin
      Game.Runtime.LastScan := Ord(ReadKey);

      case Game.Runtime.LastScan of
        72, 75, 77, 80:
          if (Game.Campaign.Map[Island, Game.Campaign.Hero.X + WorkerDirections[Game.Runtime.LastScan].X,
            Game.Campaign.Hero.Y + WorkerDirections[Game.Runtime.LastScan].Y] >= Base)
            and (Game.Campaign.Map[Island, Game.Campaign.Hero.X + WorkerDirections[Game.Runtime.LastScan].X,
              Game.Campaign.Hero.Y + WorkerDirections[Game.Runtime.LastScan].Y] < Base + Span)
          then
          begin
            X := Game.Campaign.Hero.X + WorkerDirections[Game.Runtime.LastScan].X;
            Y := Game.Campaign.Hero.Y + WorkerDirections[Game.Runtime.LastScan].Y;
            Tile := Replacement;

            if (Island = 5) and (Base = 80) and (Game.Runtime.RegrowthPosition.X = 100) then
            begin
              Game.Runtime.RegrowthPosition.X := X;
              Game.Runtime.RegrowthPosition.Y := Y;
              Game.Runtime.RegrowthCountdown := 6;
            end;

            if Replacement = 0 then
            begin
              if (Game.Campaign.Map[Island, X, Y - 1] >= Base)
                and (Game.Campaign.Map[Island, X, Y - 1] < Base + Span) then
                Dec(Game.Campaign.Map[Island, X, Y - 1], 2);
              if (Game.Campaign.Map[Island, X, Y + 1] >= Base)
                and (Game.Campaign.Map[Island, X, Y + 1] < Base + Span) then
                Dec(Game.Campaign.Map[Island, X, Y + 1], 1);
              if (Game.Campaign.Map[Island, X - 1, Y] >= Base)
                and (Game.Campaign.Map[Island, X - 1, Y] < Base + Span) then
                Dec(Game.Campaign.Map[Island, X - 1, Y], 8);
              if (Game.Campaign.Map[Island, X + 1, Y] >= Base)
                and (Game.Campaign.Map[Island, X + 1, Y] < Base + Span) then
                Dec(Game.Campaign.Map[Island, X + 1, Y], 4);
            end;

            if Replacement = 48 then
            begin
              if (Game.Campaign.Map[Island, X, Y - 1] >= Replacement)
                and (Game.Campaign.Map[Island, X, Y - 1] < Replacement + 16) then
              begin
                Tile := Tile + 1;
                Game.Campaign.Map[Island, X, Y - 1] := Game.Campaign.Map[Island, X, Y - 1] + 2;
              end;

              if (Game.Campaign.Map[Island, X, Y + 1] >= Replacement)
                and (Game.Campaign.Map[Island, X, Y + 1] < Replacement + 16) then
              begin
                Tile := Tile + 2;
                Game.Campaign.Map[Island, X, Y + 1] := Game.Campaign.Map[Island, X, Y + 1] + 1;
              end;

              if (Game.Campaign.Map[Island, X - 1, Y] >= Replacement)
                and (Game.Campaign.Map[Island, X - 1, Y] < Replacement + 16) then
              begin
                Tile := Tile + 4;
                Game.Campaign.Map[Island, X - 1, Y] := Game.Campaign.Map[Island, X - 1, Y] + 8;
              end;

              if (Game.Campaign.Map[Island, X + 1, Y] >= Replacement)
                and (Game.Campaign.Map[Island, X + 1, Y] < Replacement + 16) then
              begin
                Tile := Tile + 8;
                Game.Campaign.Map[Island, X + 1, Y] := Game.Campaign.Map[Island, X + 1, Y] + 4;
              end;
            end;

            Game.Campaign.Map[Island, X, Y] := Tile;
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
  Str(Game.Campaign.Carpenters, Number);
  DrawText(false, 16, 256, Number);
  DrawText(false, 2, 264, '2) ‹¥á®pã¡ë :');
  Str(Game.Campaign.Woodcutters, Number);
  DrawText(false, 16, 264, Number);
  DrawText(false, 2, 272, '3) ‡¥¬«¥ª®¯ë:');
  Str(Game.Campaign.Diggers, Number);
  DrawText(false, 16, 272, Number);
  DrawText(false, 2, 280, '4) Š ¬­¥â¥áë:');
  Str(Game.Campaign.Stonecutters, Number);
  DrawText(false, 16, 280, Number);
  Game.Runtime.LastScan := Ord(ReadKey);

  case Game.Runtime.LastScan of
    49: if Game.Campaign.Carpenters > 0 then EditTerrain(Game.Campaign.Carpenters, 32, 32, 4)
    else HeaderPrompt(8);
    50: if Game.Campaign.Woodcutters > 0 then EditTerrain(Game.Campaign.Woodcutters, 64, 16, 0)
    else HeaderPrompt(8);
    51: if Game.Campaign.Diggers > 0 then EditTerrain(Game.Campaign.Diggers, 0, 1, 48)
    else HeaderPrompt(8);
    52: if Game.Campaign.Stonecutters > 0 then EditTerrain(Game.Campaign.Stonecutters, 80, 16, 0)
    else HeaderPrompt(8);
  else Game.Runtime.LastScan := 48;
  end;
end;

end.
