unit KBView;
{$G+,R-,S-,I+,A+}

interface

procedure DrawAdventureField;

implementation

uses KBState, KBGfx;

procedure DrawAdventureField;
begin
  DrawPictureTile(1761, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y - 2]);
  DrawPictureTile(1773, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y - 2]);
  DrawPictureTile(1785, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y - 2]);
  DrawPictureTile(1797, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y - 2]);
  DrawPictureTile(1809, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y - 2]);

  DrawPictureTile(6561, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y - 1]);
  DrawPictureTile(6573, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y - 1]);
  DrawPictureTile(6585, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y - 1]);
  DrawPictureTile(6597, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y - 1]);
  DrawPictureTile(6609, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y - 1]);

  DrawPictureTile(11361, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y]);
  DrawPictureTile(11373, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y]);

  if Game.Runtime.ShipAbandonBlocked then DrawTile(11385, Game.Campaign.Map[Game.Campaign.Island,
    Game.Campaign.Hero.X, Game.Campaign.Hero.Y], 15)
  else DrawTile(11385, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y], 6);
  DrawPictureTile(11397, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y]);
  DrawPictureTile(11409, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y]);

  DrawPictureTile(16161, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16173, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16185, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16197, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y + 1]);
  DrawPictureTile(16209, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y + 1]);

  DrawPictureTile(20961, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 2, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20973, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X - 1, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20985, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(20997, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 1, Game.Campaign.Hero.Y + 2]);
  DrawPictureTile(21009, Game.Campaign.Map[Game.Campaign.Island, Game.Campaign.Hero.X + 2, Game.Campaign.Hero.Y + 2]);
end;

end.
