unit KBBattle;
{$G+,R-,S-,I+,A+}

interface

procedure Battle(EnemyTypes, EnemyCounts: pointer; TerrainDensity: byte);

implementation

uses KBState, KBBType, KBUI, KBArt, KBGfx, KBInput, KBFiles, KBTables, Crt, KBSound;

{$I COMBAT.INC}
end.
