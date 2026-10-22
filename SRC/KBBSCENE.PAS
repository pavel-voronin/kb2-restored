unit KBBScene;
{$G+,R-,S-,I+,A+}

interface

uses KBBType;

procedure PaintBattleTerrain(var Combat: TBattleState; TerrainDensity: byte);
procedure BattleHelp;

implementation

uses KBState, KBTables, KBUI, KBGfx, KBInput, Crt, KBBMagic;

procedure PaintBattleTerrain(var Combat: TBattleState; TerrainDensity: byte);
var
  I, Terrain: byte;

begin
  for I := 0 to 29 do DrawPictureTile(BattleCellOffsets[I], 0);
  for I := 0 to 7 do DrawLine(I + 584, 23, I + 584, 321, 10);

  case Game.Campaign.Island of
    1, 3: Terrain := 64;
    2: Terrain := 48;
    4, 5: Terrain := 80;
  end;

  I := Random(TerrainDensity);
  while I > 0 do
  begin
    Combat.Cell := Random(149) div 5;
    DrawPictureTile(BattleCellOffsets[Combat.Cell], Terrain);
    Game.Runtime.BattleField[Combat.Cell mod 6, Combat.Cell div 6] := Terrain;
    Dec(I);
  end;
end;

procedure BattleHelp;

const
  ReserveHelp = '( A )  Ввод pезеpва';
  ShowUnitsHelp = '( B )  Показать своих воинов';
  EndTurnHelp = '( E )  Пеpедача хода пpотивнику';
  FlyHelp = '( F )  Пpиказ: лететь';
  MoveHelp = '( M )  Пpиказ: идти';
  NextUnitHelp = '( N )  Куpсоp на следующего воина';
  ShootHelp = '( S )  Пpиказ: стpелять';
  MagicHelp = '( U )  Волшебство';
  FleeHelp = '(F10)  Бежать с поля боя';

begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, ReserveHelp);
  DrawText(false, 2, 248, ShowUnitsHelp);
  DrawText(false, 2, 256, EndTurnHelp);
  DrawText(false, 2, 264, FlyHelp);
  DrawText(false, 2, 272, MoveHelp);
  DrawText(false, 2, 280, NextUnitHelp);
  DrawText(false, 2, 288, ShootHelp);
  DrawText(false, 2, 296, MagicHelp);
  DrawText(false, 2, 304, FleeHelp);
  Game.Runtime.LastScan := ReadScanCode;
  RedrawLowerRows;
end;

end.
