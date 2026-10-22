unit KBHud;
{$G+,R-,S-,I+,A+}

interface

procedure RefreshMagic;
procedure RefreshGold;
procedure RefreshMapParts;

implementation

uses KBAdvent, KBGfx, Crt, KBState;

procedure RefreshMagic;
begin
  if (Game.Campaign.MagicPower > 9) and (Game.Campaign.HiddenSpellIsland = 100) then PlaceHiddenSpell;
  case Game.Campaign.MagicPower of
    0: begin
      ClearPicturePlanes(11422, 7);
      DrawPicturePlanes(11422, 19, 8)
    end;

    1..2: begin
      ClearPicturePlanes(11422, 13);
      DrawPicturePlanes(11422, 19, 2)
    end;

    3..4: begin
      ClearPicturePlanes(11422, 3);
      DrawPicturePlanes(11422, 19, 12)
    end;

    5..6: begin
      ClearPicturePlanes(11422, 12);
      DrawPicturePlanes(11422, 19, 3)
    end;

    7..8: begin
      ClearPicturePlanes(11422, 9);
      DrawPicturePlanes(11422, 19, 6)
    end;

    9..10: begin
      ClearPicturePlanes(11422, 8);
      DrawPicturePlanes(11422, 19, 7)
    end;

    11..12: begin
      ClearPicturePlanes(11422, 6);
      DrawPicturePlanes(11422, 19, 9)
    end;

    13..14: begin
      ClearPicturePlanes(11422, 2);
      DrawPicturePlanes(11422, 19, 13)
    end;

    15..16: begin
      ClearPicturePlanes(11422, 5);
      DrawPicturePlanes(11422, 19, 10)
    end;

    17..18: begin
      ClearPicturePlanes(11422, 1);
      DrawPicturePlanes(11422, 19, 14)
    end;

    19..20: begin
      ClearPicturePlanes(11422, 4);
      DrawPicturePlanes(11422, 19, 11)
    end;
  else DrawPictureTile(11422, 19);
  end;
end;

procedure RefreshGold;
begin
  if Game.Campaign.Gold < 2000 then
  begin
    ClearPicturePlanes(16222, 7);
    DrawPicturePlanes(16222, 21, 8)
  end
  else if Game.Campaign.Gold < 5000 then
  begin
    ClearPicturePlanes(16222, 14);
    DrawPicturePlanes(16222, 21, 1)
  end
  else if Game.Campaign.Gold < 10000 then
  begin
    ClearPicturePlanes(16222, 6);
    DrawPicturePlanes(16222, 21, 9)
  end
  else if Game.Campaign.Gold < 20000 then
  begin
    ClearPicturePlanes(16222, 13);
    DrawPicturePlanes(16222, 21, 2)
  end
  else if Game.Campaign.Gold < 50000 then
  begin
    ClearPicturePlanes(16222, 12);
    DrawPicturePlanes(16222, 21, 3)
  end
  else if Game.Campaign.Gold < 75000 then
  begin
    ClearPicturePlanes(16222, 5);
    DrawPicturePlanes(16222, 21, 10)
  end
  else if Game.Campaign.Gold < 100000 then
  begin
    ClearPicturePlanes(16222, 4);
    DrawPicturePlanes(16222, 21, 11)
  end
  else if Game.Campaign.Gold < 150000 then
  begin
    ClearPicturePlanes(16222, 8);
    DrawPicturePlanes(16222, 21, 7)
  end
  else if Game.Campaign.Gold < 200000 then
  begin
    ClearPicturePlanes(16222, 3);
    DrawPicturePlanes(16222, 21, 12)
  end
  else if Game.Campaign.Gold < 500000 then
  begin
    ClearPicturePlanes(16222, 2);
    DrawPicturePlanes(16222, 21, 13)
  end
  else if Game.Campaign.Gold < 800000 then
  begin
    ClearPicturePlanes(16222, 1);
    DrawPicturePlanes(16222, 21, 14)
  end
  else DrawPictureTile(16222, 21);
end;

procedure RefreshMapParts;
begin
  case Game.Campaign.MapParts of
    0: begin
      ClearPicturePlanes(21022, 7);
      DrawPicturePlanes(21022, 20, 8)
    end;

    1: begin
      ClearPicturePlanes(21022, 3);
      DrawPicturePlanes(21022, 20, 12)
    end;

    2: begin
      ClearPicturePlanes(21022, 2);
      DrawPicturePlanes(21022, 20, 13)
    end;

    3: begin
      ClearPicturePlanes(21022, 1);
      DrawPicturePlanes(21022, 20, 14)
    end;

    4: begin
      ClearPicturePlanes(21022, 4);
      DrawPicturePlanes(21022, 20, 11)
    end;
  else DrawPictureTile(21022, 20);
  end;
end;
end.
