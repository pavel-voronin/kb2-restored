unit KBInit;
{ Начальные значения до создания или загрузки кампании. }
{$G+,R-,S-,I+,A+}

interface

procedure InitializeLegacyState;

implementation

uses KBArt, KBState;

const
  SubjectOne = 'SUBJECT1.PIC';
  SubjectTwo = 'SUBJECT2.PIC';
  DesertPicture = 'DESERT.PIC';
  WaterPicture = 'WATER.PIC';
  WoodPicture = 'WOOD.PIC';
  MountainPicture = 'MOUNTAIN.PIC';
  EnemyPicture = 'ENEMY.PIC';
  ReservePicture = 'ARMY5.PIC';

procedure InitializeLegacyState;
begin
  Game.Runtime.CurrentContractOffer := 1;
  Game.Runtime.GoodsMarketTown := 255;
  Game.Runtime.GoodsMarketIsland := 1;
  Game.Runtime.ShipAbandonBlocked := false;
  Game.Runtime.SubjectOneFileName := SubjectOne;
  Game.Runtime.SubjectTwoFileName := SubjectTwo;
  Game.Runtime.BattlePictureFileName := DesertPicture;
  Game.Runtime.WaterPictureFileName := WaterPicture;
  Game.Runtime.IslandPictureFileName := WoodPicture;
  Game.Runtime.ChartPictureFileName := MountainPicture;
  Game.Runtime.EnemyPictureFileName := EnemyPicture;
  Game.Runtime.ReservePictureFileName := ReservePicture;

  for Game.Runtime.InitIndex := 1 to 4 do
  begin
    Game.World.GenerationX := Random(20);

    if Game.World.GenerationX < 10 then Game.Campaign.Flags.PaperChartPresent[Game.Runtime.InitIndex] := false
    else Game.Campaign.Flags.PaperChartPresent[Game.Runtime.InitIndex] := true;
  end;

  Game.Campaign.Flags.PaperChartPresent[5] := false;
  Game.Campaign.SceneIsland := 1;
  Game.Campaign.ShipHeading := 1;
  AllocateArtwork;
  Game.Runtime.SoundDisabled := false;
end;
end.
