unit KBBType;
{$G+,R-,S-,A+}

interface

type
  PEnemySpecies = ^TEnemySpecies;
  TEnemySpecies = array[0..4] of byte;
  PEnemyCounts = ^TEnemyCounts;
  TEnemyCounts = array[0..4] of word;
  TReserveState = packed record
    Text: string[60];
    ReserveMode: boolean;
    FieldX, UnknownAfterFieldX, Selected, Count: byte;
    ReserveSlots: array[1..5] of byte;
    UnknownAfterReserveSlots: byte;
    ActiveSlots: array[1..5] of byte;
    UnknownAfterActiveSlots: byte;
  end;

  TEnemyAIState = packed record
    Distance: word;
    StepsLeft: byte;
    EnemyY, EnemyX, TargetY, TargetX, PreviousRank, EnemySlot: byte;
    TurnResult, TestY, TestX: byte;
    BestY, BestX: shortint;
    UnknownBeforeScanIndex: byte;
    ScanIndex: shortint;
    StepRanks: array[0..2] of shortint;
    UnknownAfterStepRanks: byte;
    CandidateY, CandidateX: array[0..3] of shortint;
    PreferredTargets: array[0..2] of shortint;
    UnknownBeforeCosts: array[0..6] of byte;
    MovementCosts: array[0..5, 0..4] of byte;
  end;

  TCombatUnit = packed record
    Species: byte;
    CanFly: boolean;
    Shots: byte;
    Count: word;
    HitPoints, AttackPower: longint;
    InitialCount: word;
  end;

  TBattleState = packed record
    UnknownPrefix: byte;
    EnemyCount, ReadyPlayerCount, PlayerCount: byte;
    RoundMagicReady: boolean;
    DemonHalved: boolean;
    TeleportSelected: boolean;
    EnemyPhaseFinished: boolean;
    Uncontrolled: array[0..4] of boolean;
    UnknownAfterControlFlags: byte;
    CanMove: array[0..4] of boolean;
    UnknownAfterMoveFlags: byte;
    MutantResists: array[25..29] of byte;
    UnknownAfterMutantResists: byte;
    DragonResists, DemonResists: byte;
    TeleportY, TeleportX: byte;
    TargetY: byte;
    Cell: byte;
    CursorY, CursorX: byte;
    FrozenEnemySlot: byte;
    TargetSlot: byte;
    SpawnI, UnknownAfterSpawnIndex, MainI, MaxReserve: byte;
    LeadershipLimit: word;
    VampireInitialCount: word;
    ScaleCount: longint;
    Retaliations: array[0..4] of byte;
    UnknownAfterRetaliations: byte;
    Poison: array[0..4] of byte;
    UnknownAfterPoison: byte;
    Enemy, Player: array[0..9] of TCombatUnit;
  end;

implementation

end.
