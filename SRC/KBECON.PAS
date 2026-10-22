unit KBEcon;
{$G+,R-,S-,I+,A+}

interface

function PaymentFailed(Cost: longint): boolean;
function ReadQuantity(var Quantity: longint): boolean;
procedure BuyQuantity(Capacity, Price: word; var Destination, Stock: word);
procedure BuyByteQuantity(Capacity, Price: word; var Destination: word; var Stock: byte);

implementation

uses KBHud, KBUI, KBGfx, KBSound, Crt, KBState;

function PaymentFailed(Cost: longint): boolean;
var
  Page: word;

begin
  if Game.Campaign.Gold >= Cost then
  begin
    Game.Campaign.Gold := Game.Campaign.Gold - Cost;
    PaymentFailed := false;
    Page := Game.Runtime.PicturePage;
    Game.Runtime.PicturePage := 0;
    RefreshGold;
    Game.Runtime.PicturePage := Page;
  end
  else
  begin
    PaymentFailed := true;
    ShowNotice(1);
  end;
end;

function ReadQuantity(var Quantity: longint): boolean;

const
  Caption = 'C'#170#174#171#236#170#174'?';
  Blank = ' ';

var
  Digits: byte;

begin
  HeaderPrompt(7);
  Game.Runtime.QuantityText := '';
  Digits := 0;
  DrawText(false, 45, 304, Caption);

  repeat
    Game.Runtime.LastScan := Ord(ReadKey);
    case Game.Runtime.LastScan of
      8: if Digits > 0 then
      begin
        Delete(Game.Runtime.QuantityText, Digits, 1);
        DrawText(false, Digits + 53, 304, Blank);
        Dec(Digits);
      end;

      48..57: begin
        Game.Runtime.QuantityText := Concat(Game.Runtime.QuantityText, Chr(Game.Runtime.LastScan));
        Inc(Digits);
        DrawText(false, 54, 304, Game.Runtime.QuantityText);
      end;
    end;
  until (Game.Runtime.LastScan = 13) or (Game.Runtime.LastScan = 27) or (Digits > 5);
  ReadQuantity := Game.Runtime.LastScan <> 27;
  Val(Game.Runtime.QuantityText, Quantity, Game.World.GenerationCount);
end;

procedure BuyQuantity(Capacity, Price: word; var Destination, Stock: word);
var
  Quantity, Cost: longint;

begin
  if ReadQuantity(Quantity) then
    if Stock >= Quantity then
      if Capacity >= Quantity then
      begin
        if Game.Campaign.Gold > 5000 then Cost := Price * Quantity
        else Cost := Random(Price * Quantity);

        if PaymentFailed(Cost) then Game.Runtime.LastScan := 27
        else
        begin
          Game.Runtime.CueFrequency := Cost div 10;
          PlayCue(4);
          Destination := Destination + Quantity;
          Stock := Stock - Quantity;
        end;
      end;
end;

procedure BuyByteQuantity(Capacity, Price: word; var Destination: word; var Stock: byte);
var
  Temporary: word;

begin
  Temporary := Stock;
  BuyQuantity(Capacity, Price, Destination, Temporary);
  Stock := Temporary;
end;
end.
