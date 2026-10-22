unit KBState;
{$G+,R-,S-,A+}

interface

uses KBTypes;

type
  TGameState = packed record
    DataFileName: string[12];
    Unknown_0C4B: array[1..1] of byte;
    MoneyFileName: string[9];
    FontFileName: string[12];
    Unknown_0C63: array[1..1] of byte;
    FontPointer: pointer;
    WorkerRestockPhase: boolean; { Работники пополняются раз в две недели. }
    IdleCounter: byte;
    IdlePowerPhase: byte;
    WealthPicture: byte;
    RegrowthPosition: TPosition;
    RegrowthCountdown: byte;
    ShoreTile: byte;
    SpiritStonePosition: TSignedPosition;
    InstructionCounter: byte;
    Unknown_0C73: array[1..2] of byte;

    ArrangementCount: byte;
    AuthorityChange: word;
    ArrangementText: string[60];
    Unknown_0CB5: array[1..1] of byte;
    ArrangementOverflow: TArmyStack;
    Unknown_0CB9: array[1..1] of byte;
    ActiveArmyRows: array[1..5] of byte;
    Unknown_0CBF: array[1..1] of byte;
    ReserveArmyRows: array[1..5] of byte;
    Unknown_0CC5: array[1..1] of byte;
    ArrangementOriginal: array[0..4] of TArmyStack;
    Unknown_0CD5: array[1..15] of byte;
    ArrangementReserve: boolean;
    MagicCastSucceeded: boolean;
    CalmArmyPicture: pointer;
    QuantityText: string[10];
    Unknown_0CF5: array[1..1] of byte;
    SpellTitles: array[0..7] of string[10];
    ShipAbandonBlocked: boolean;

    GoodsMarketAge: byte;
    GoodsMarketTown: byte;
    TownPictureLoaded: boolean;
    GoodsMarketIsland: byte;
    Unknown_0D53: array[1..1] of byte;
    GoodsStock: array[1..7] of byte;
    Unknown_0D5B: array[1..1] of byte;
    GoodsBuyPrices: array[1..7] of word;
    GoodsSellPrices: array[1..7] of word;
    CurrentContractOffer: byte;
    Unknown_0D79: array[1..1] of byte;
    RoamerDirection: word;
    InitIndex: byte;
    Unknown_0D7D: array[1..1] of byte;
    Lst: text;
    SubjectOneFileName: string[13];
    SubjectTwoFileName: string[13];
    BattlePictureFileName: string[13];
    WaterPictureFileName: string[13];
    IslandPictureFileName: string[13];
    ChartPictureFileName: string[13];
    EnemyPictureFileName: string[13];

    BattleValue: longint;
    BattlePriceTemporary: longint;
    CachedCreatureId: byte;
    Unknown_0EE9: array[1..1] of byte;
    TextBuffer: string[25];
    LastScan: byte;
    BattleResult: byte;
    BattleField: array[0..5, 0..4] of byte;
    BattleDistances: array[0..5, 0..4] of word;
    BattleTextColumn: word;
    CurrentBattleSlot: byte;
    Unknown_0F63: array[1..1] of byte;

    CueFrequency: word;
    SoundDisabled: boolean;
    Unknown_0F67: array[1..1] of byte;
    Font: array[0..255, 0..7] of byte;
    PictureBanks: array[0..14] of pointer;
    PictureMask: array[0..719] of byte;
    PictureFileName: string[13];
    ReservePictureFileName: string[9];
    BlitDestSegment: word;
    BlitSourceSegment: word;
    BlitOverlaySegment: word;
    BlitDestOffset: word;
    BlitSourceOffset: word;
    BlitOverlayOffset: word;
    PicturePage: word;
    IslandBufferOffset: word;
    ViewportBufferOffset: word;
    WorldMapPending: byte;
    BlitWordsLeft: byte;
    WorldMapRedraw: byte;
    StepX: shortint;
    StepY: shortint;
    ActionScratch: byte;
    Unknown_1AA4: array[1..2] of byte;
    RoamerNextX, RoamerNextY: byte;
    ViewportLeftX, ViewportTopY: byte;
    Unknown_1AAA: array[1..2] of byte;

    { Отсюда начинаются флаги сохранения. }
    Discovery: array[1..5, 0..65, 0..65] of boolean;
    LocalMapOwned: array[1..5] of boolean;
    Unknown_6FC5: array[1..1] of byte;
    PaperChartPresent: array[1..5] of boolean;
    Unknown_6FCB: array[1..1] of byte;
    SpellAvailable: array[0..7] of boolean;
    SpellUsed: array[0..7] of boolean;
    ArmyAvailable: boolean;
    ShipOwned: boolean;
    SiegeEngineOwned: boolean;
    Heading: boolean;
    InstructionsShown: boolean;
    Unknown_6FE1: array[1..1] of byte;

    { Эта часть записывается в файл без упаковки. }
    VisitedCastles: array[0..25] of TContract;
    VisitedTowns: array[0..25] of TContract;
    Contracts: array[1..5, 1..5] of TContract;
    Cargo: array[1..7] of word;
    CargoMaxPrices: array[1..7] of word;
    QuestFlags: array[1..5] of byte;
    Unknown_709D: array[1..1] of byte;
    WizardRelations: array[1..5] of byte;
    Unknown_70A3: array[1..1] of byte;

    Hero: TSignedPosition;
    HiddenSpellIsland: byte;
    HiddenSpellPosition: TPosition;
    HiddenSpellEffect: word;
    Unknown_70AB: array[1..1] of byte;
    RitualStoneIsland: byte;
    RitualStonePosition: TPosition;
    Unknown_70AF: array[1..5] of byte;
    GuardianSpecies: array[0..4] of byte;
    GuardianCounts: array[0..4] of word;
    Unknown_70C3: array[1..1] of byte;
    SpellColors: array[0..7] of byte;
    Relics: array[2..5] of TRelic;

    Ship: TSignedPosition;
    ShipIsland: byte;
    ShipHeading: byte;
    ContractIsland: byte;
    ContractSlot: byte;
    Gold: longint;
    Carpenters: word;
    Woodcutters: word;
    Stonecutters: word;
    Diggers: word;
    ExtraDays: word;
    ScrollCapacity: byte;
    Difficulty: byte;
    HighestVisitedIsland: byte;
    UnlockedIslands: byte;
    SceneIsland: byte;
    Unknown_70ED: array[1..1] of byte;

    Map: array[1..5, 0..65, 0..65] of byte;

    Castles: array[1..5, 1..5] of TCastle;
    Unknown_C841: array[1..1] of byte;
    Towns: array[1..5, 1..5] of TTown;
    Dwellings: array[1..5, 0..7] of TDwelling;
    WanderingArmies: array[1..5, 0..20] of TWanderingArmy;
    Unknown_D0CB: array[1..1] of byte;
    Underground: array[1..5, 1..2] of TSignedPosition;

    Army: array[0..9] of TArmyStack;
    Mutants: array[25..29] of TCreatureDefinition;
    Scrolls: array[0..13] of byte;

    Leadership: longint;
    LeadershipBonus: longint;
    DamageBonus: word;
    MagicPower: byte;
    RitualPower: byte;
    WeeklySpecies: byte;
    Unknown_D173: array[1..1] of byte;
    WizardVisited: array[1..5] of byte;
    Unknown_D179: array[1..5] of byte;
    Income: longint;
    Weeks: word;
    MapParts: byte;
    Days: byte;
    ArchivedIsland: byte;
    ArchiveMarker: byte;
    Island: byte;
    EnemyGrace: byte;
    TornadoCharges: byte;
    ShipBackground: byte;

    { Дальше идут рабочие переменные, они не сохраняются. }
    WizardPosition: TPosition;
    WizardAge: word;
    MagePosition: TPosition;
    MageAge: word;
    GenerationCount: word;
    GenerationLimit: word;
    TimeStopAccumulated: word;
    GenerationX: byte;
    GenerationY: byte;
    TownNamePool: array[0..27] of byte;
    CastleNamePool: array[0..27] of byte;
    SpellColorPool: array[0..7] of byte;
    GenerationIsland: byte;
    GenerationChoice: byte;
  end;

var
  Game: TGameState;

implementation

end.
