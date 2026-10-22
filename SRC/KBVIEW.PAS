unit KBView;
{$G+,R-,S-,I+,A+}

interface

procedure DrawAdventureField;

implementation

uses KBState, KBGfx;

procedure DrawAdventureField;
begin
  DrawPictureTile(1761, Game.Map[Game.Island, Game.Hero.X - 2, Game.Hero.Y - 2]);
  DrawPictureTile(1773, Game.Map[Game.Island, Game.Hero.X - 1, Game.Hero.Y - 2]);
  DrawPictureTile(1785, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y - 2]);
  DrawPictureTile(1797, Game.Map[Game.Island, Game.Hero.X + 1, Game.Hero.Y - 2]);
  DrawPictureTile(1809, Game.Map[Game.Island, Game.Hero.X + 2, Game.Hero.Y - 2]);

  DrawPictureTile(6561, Game.Map[Game.Island, Game.Hero.X - 2, Game.Hero.Y - 1]);
  DrawPictureTile(6573, Game.Map[Game.Island, Game.Hero.X - 1, Game.Hero.Y - 1]);
  DrawPictureTile(6585, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y - 1]);
  DrawPictureTile(6597, Game.Map[Game.Island, Game.Hero.X + 1, Game.Hero.Y - 1]);
  DrawPictureTile(6609, Game.Map[Game.Island, Game.Hero.X + 2, Game.Hero.Y - 1]);

  DrawPictureTile(11361, Game.Map[Game.Island, Game.Hero.X - 2, Game.Hero.Y]);
  DrawPictureTile(11373, Game.Map[Game.Island, Game.Hero.X - 1, Game.Hero.Y]);

  if Game.ShipAbandonBlocked then DrawTile(11385, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y], 15)
  else DrawTile(11385, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y], 6);
  DrawPictureTile(11397, Game.Map[Game.Island, Game.Hero.X + 1, Game.Hero.Y]);
  DrawPictureTile(11409, Game.Map[Game.Island, Game.Hero.X + 2, Game.Hero.Y]);

  DrawPictureTile(16161, Game.Map[Game.Island, Game.Hero.X - 2, Game.Hero.Y + 1]);
  DrawPictureTile(16173, Game.Map[Game.Island, Game.Hero.X - 1, Game.Hero.Y + 1]);
  DrawPictureTile(16185, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y + 1]);
  DrawPictureTile(16197, Game.Map[Game.Island, Game.Hero.X + 1, Game.Hero.Y + 1]);
  DrawPictureTile(16209, Game.Map[Game.Island, Game.Hero.X + 2, Game.Hero.Y + 1]);

  DrawPictureTile(20961, Game.Map[Game.Island, Game.Hero.X - 2, Game.Hero.Y + 2]);
  DrawPictureTile(20973, Game.Map[Game.Island, Game.Hero.X - 1, Game.Hero.Y + 2]);
  DrawPictureTile(20985, Game.Map[Game.Island, Game.Hero.X, Game.Hero.Y + 2]);
  DrawPictureTile(20997, Game.Map[Game.Island, Game.Hero.X + 1, Game.Hero.Y + 2]);
  DrawPictureTile(21009, Game.Map[Game.Island, Game.Hero.X + 2, Game.Hero.Y + 2]);
end;


end.
