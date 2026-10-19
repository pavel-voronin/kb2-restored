unit KBTables;
{$G+,R-,S-,A+}

interface

type
  TDirection = packed record
    X, Y: shortint
  end;

  TCreatureCost = packed record
    case boolean of
      false: (Price: word);
      true: (Weeks, Appearance: byte);
  end;

  TCreatureDefinition = packed record
    Name: string[9];
    Cost: TCreatureCost;
    Movement, Flags: byte;
    Defense, Attack: word;
  end;

const
  UnknownProgramPrefix: array[1..12] of byte = (
    1,
    1,
    0,
    1,
    1,
    1,
    0,
    1,
    1,
    0,
    0,
    0);

  IslandFactors: array[1..5] of word = (
    50,
    100,
    150,
    200,
    500);

  TreasureGoldBases: array[1..5] of word = (
    5,
    25,
    50,
    75,
    200);

  SoundToggleCaptions: array[0..1] of string[9] = (
    '¢ëª«îç¨âì',
    '¢ª«îç¨âì');

  WorkerDirections: array[72..80] of TDirection = (
    (X: 0; Y: -1),
    (X: 0; Y: 0),
    (X: 0; Y: 0),
    (X: -1; Y: 0),
    (X: 0; Y: 0),
    (X: 1; Y: 0),
    (X: 0; Y: 0),
    (X: 0; Y: 0),
    (X: 0; Y: 1));

  RulerNames: array[1..5] of string[14] = (
    '–€œ ƒ‚ˆ„',
    '—…›‰ ‚„Ÿ‰',
    'ŠŸ‡œ …Š“’',
    '‘…†›‰ €‘',
    '‡Œ…‰ ””ˆ');

  IslandIncomeFactors: array[1..5] of word = (
    50,
    100,
    150,
    200,
    500);

  PrinterColumnPatterns: array[1..9] of array[0..7] of byte = (
    (129, 0, 0, 24, 24, 0, 0, 129),
    (255, 255, 255, 255, 255, 255, 255, 255),
    (170, 85, 170, 85, 170, 85, 170, 85),
    (255, 0, 0, 255, 0, 0, 255, 0),
    (146, 146, 146, 146, 146, 146, 146, 146),
    (24, 24, 24, 255, 255, 24, 24, 24),
    (65, 99, 54, 28, 28, 54, 99, 65),
    (0, 0, 0, 0, 0, 0, 0, 0),
    (126, 6, 14, 126, 14, 6, 126, 0));

  ShipPurchasePrice: word = 500;

  WanderingSpeciesBases: array[1..5] of byte = (
    0,
    5,
    10,
    12,
    15);

  SummoningSpeciesLimits: array[1..5] of byte = (
    9,
    14,
    19,
    24,
    24);

  WeeklyDwellingCapacities: array[0..24] of word = (
    1000,
    400,
    500,
    500,
    500,
    200,
    200,
    200,
    200,
    200,
    100,
    100,
    100,
    100,
    100,
    30,
    50,
    50,
    50,
    70,
    30,
    50,
    30,
    30,
    30);

  CreatureDefinitions: array[0..29] of TCreatureDefinition = (
    (Name: 'Š…‘’œŸ…'; Cost: (Price: 50);
  Movement: 1;
  Flags: 32;
  Defense: 2;
  Attack: 1),
    (Name: '‹…˜ˆˆ'; Cost: (Price: 100);
  Movement: 1;
  Flags: 160;
  Defense: 8;
  Attack: 3),
    (Name: '’“‡…Œ–›'; Cost: (Price: 60);
  Movement: 2;
  Flags: 42;
  Defense: 5;
  Attack: 1),
    (Name: '‘Š…‹…’›'; Cost: (Price: 85);
  Movement: 2;
  Flags: 64;
  Defense: 8;
  Attack: 2),
    (Name: 'Š€€›'; Cost: (Price: 75);
  Movement: 3;
  Flags: 32;
  Defense: 7;
  Attack: 2),
    (Name: '‹œ”›'; Cost: (Price: 200);
  Movement: 2;
  Flags: 52;
  Defense: 18;
  Attack: 6),
    (Name: '‚ˆ’Ÿ‡ˆ'; Cost: (Price: 300);
  Movement: 1;
  Flags: 32;
  Defense: 25;
  Attack: 8),
    (Name: '‡Œˆ'; Cost: (Price: 250);
  Movement: 1;
  Flags: 64;
  Defense: 22;
  Attack: 6),
    (Name: 'ƒˆ‹‹›'; Cost: (Price: 200);
  Movement: 2;
  Flags: 32;
  Defense: 20;
  Attack: 6),
    (Name: 'Š€‹ˆŠˆ'; Cost: (Price: 200);
  Movement: 1;
  Flags: 32;
  Defense: 20;
  Attack: 6),
    (Name: '„“ˆ„›'; Cost: (Price: 500);
  Movement: 3;
  Flags: 37;
  Defense: 60;
  Attack: 22),
    (Name: '‹œ‚›'; Cost: (Price: 800);
  Movement: 4;
  Flags: 32;
  Defense: 70;
  Attack: 22),
    (Name: 'ˆ‡€Šˆ'; Cost: (Price: 600);
  Movement: 3;
  Flags: 32;
  Defense: 70;
  Attack: 15),
    (Name: 'Š€ˆ€‹›'; Cost: (Price: 700);
  Movement: 2;
  Flags: 32;
  Defense: 60;
  Attack: 30),
    (Name: '’‹ˆ'; Cost: (Price: 1000);
  Movement: 1;
  Flags: 96;
  Defense: 100;
  Attack: 25),
    (Name: '‡Œ…ˆ'; Cost: (Price: 1500);
  Movement: 1;
  Flags: 32;
  Defense: 70;
  Attack: 65),
    (Name: '‘‹›'; Cost: (Price: 2000);
  Movement: 1;
  Flags: 64;
  Defense: 130;
  Attack: 50),
    (Name: '‚€Œˆ›'; Cost: (Price: 2000);
  Movement: 1;
  Flags: 192;
  Defense: 110;
  Attack: 40),
    (Name: 'ƒˆƒ€’›'; Cost: (Price: 3000);
  Movement: 2;
  Flags: 40;
  Defense: 120;
  Attack: 45),
    (Name: '›–€ˆ'; Cost: (Price: 3000);
  Movement: 1;
  Flags: 64;
  Defense: 150;
  Attack: 55),
    (Name: 'Š…’€‚›'; Cost: (Price: 5000);
  Movement: 3;
  Flags: 74;
  Defense: 400;
  Attack: 200),
    (Name: '„ˆ‡€‚›'; Cost: (Price: 5000);
  Movement: 2;
  Flags: 64;
  Defense: 450;
  Attack: 200),
    (Name: '„…Œ›'; Cost: (Price: 7000);
  Movement: 1;
  Flags: 192;
  Defense: 500;
  Attack: 200),
    (Name: '„€Š›'; Cost: (Price: 10000);
  Movement: 1;
  Flags: 224;
  Defense: 1000;
  Attack: 250),
    (Name: '–ˆŠ‹›'; Cost: (Price: 8000);
  Movement: 2;
  Flags: 64;
  Defense: 600;
  Attack: 400),
    (Name: 'Œ“‹€’›1'; Cost: (Weeks: 10; Appearance: 0);
  Movement: 1;
  Flags: 64;
  Defense: 10;
  Attack: 10),
    (Name: 'Œ“‹€’›2'; Cost: (Weeks: 10; Appearance: 0);
  Movement: 1;
  Flags: 64;
  Defense: 10;
  Attack: 10),
    (Name: 'Œ“‹€’›3'; Cost: (Weeks: 10; Appearance: 0);
  Movement: 1;
  Flags: 64;
  Defense: 10;
  Attack: 10),
    (Name: 'Œ“‹€’›4'; Cost: (Weeks: 10; Appearance: 0);
  Movement: 1;
  Flags: 64;
  Defense: 10;
  Attack: 10),
    (Name: 'Œ“‹€’›5'; Cost: (Weeks: 10; Appearance: 0);
  Movement: 1;
  Flags: 64;
  Defense: 10;
  Attack: 10));

  WorkerCapacities: array[1..5] of array[1..5] of array[0..3] of byte = (
    (
      (2, 3, 1, 2),
      (2, 3, 0, 1),
      (0, 2, 1, 2),
      (1, 1, 3, 1),
      (2, 1, 1, 1)),
    (
      (4, 2, 0, 0),
      (5, 1, 0, 0),
      (4, 2, 0, 4),
      (3, 1, 0, 0),
      (3, 2, 0, 2)),
    (
      (1, 4, 0, 3),
      (2, 4, 0, 3),
      (0, 5, 2, 2),
      (2, 5, 2, 1),
      (2, 3, 0, 5)),
    (
      (0, 2, 5, 1),
      (1, 1, 4, 0),
      (1, 3, 3, 1),
      (0, 3, 7, 0),
      (1, 0, 5, 0)),
    (
      (1, 0, 5, 1),
      (1, 1, 5, 0),
      (1, 0, 4, 2),
      (2, 0, 7, 3),
      (0, 1, 5, 0)));

  MainMenu: array[0..2] of string[12] = (
    '®¢ ï ¨£p   ',
    'p¥¦­ïï ¨£p ',
    'ˆ£p  á ¤¨áª ');

  MainMenuBoundary: byte = 0;

  Difficulties: array[0..3] of string[12] = (
    '’p¥­¨p®¢ª  1',
    '’p¥­¨p®¢ª  2',
    '’p¥­¨p®¢ª  3',
    '    ˆ£p     ');

  AuthorContact: string[55] = '310089 • pìª®¢ ¯p.”pã­§¥ ¤.57 ª¢.38 â.(0572)35-35-68(p)';

  CastleNames: array[0..27] of string[10] = (
    '€ŠŠ€',
    'AMMˆH',
    '€Œ€Š',
    'ˆ‘€“',
    'ƒ‹€‡ƒ',
    'ƒˆ‚ˆ—',
    '„‚…',
    'Š€‡…Š',
    'Š€…€',
    'ˆ”',
    '•€€”€’',
    'Š€Šˆ',
    '‹€-€‘',
    'Œ€˜…‹œ',
    'Œ‹€',
    '„†€Œ…€',
    '€€’',
    '€ƒ“',
    '‘“Š…',
    '’ˆ…‘’',
    '•€’“Œ',
    '-ˆŸ„',
    '’‹…„',
    '’……ƒ€',
    '‘”ˆŠ‘',
    '’€‹ˆ‘',
    '‹˜…',
    'Ÿ‘…');

  TownNames: array[0..27] of string[8] = (
    '“‰‘Š',
    'Œ€˜‚',
    '‹›‘…‚‘Š',
    'ƒ“œ…‚',
    'ƒˆ‹‚Š€',
    '…‹‚…',
    '†‹‘Š',
    '‡ˆƒ‡ƒCK',
    'ˆ‚€‚Š€',
    'Š‚',
    '‹…‚€„€',
    'Œ‘Š€‹…‚',
    '“†€‹‚‘Š',
    '‘‚€',
    'ˆ•€’Šˆ',
    'ƒ€œ',
    '‘€‹€’‚',
    '’ˆŠ€',
    'Š€ˆŠ€',
    '‘•€’›‰',
    '•€œŠ‚',
    '‘…’',
    '€‚€ˆŸ',
    '˜ˆ˜Šˆ',
    '™“—œ…',
    '‘Š',
    '†›‰',
    'Ÿ’€›‰');

  ScrollNames: array[0..13] of string[17] = (
    '‘’€‚Š€ ‚…Œ…ˆ',
    'CŒˆ!',
    '……•„ Š ‡€ŒŠ“',
    '……•„ Š ƒ„“',
    '„€’œ €Œˆ',
    'Š‚€‡ˆ €‚’ˆ’…’',
    '„€’œ ‚‹˜…‘’‚',
    '’…‹…’',
    '€‡Œ†…ˆ…',
    '˜€‚€Ÿ Œ‹ˆŸ',
    'Œ‡',
    '„“ˆŠ€',
    '‚‘Š…˜…ˆ…',
    'ˆ”…Š–ˆŸ');

  ScrollPrices: array[0..13] of word = (
    500,
    2000,
    1500,
    1000,
    5000,
    1500,
    2000,
    500,
    2000,
    3000,
    500,
    1000,
    5000,
    3000);

  WizardNames: array[1..6] of string[31] = (
    '6) ˆ§¬¥­¨âì ¢®«è¥¡áâ¢ ($100000)',
    '6) — áâì ¤p¥¢­¥© ª pâë($500000)',
    '6) ¡­®¢¨âì p ¡®â­¨ª®¢($200000)',
    '6) ‡ á¥«¨âì ¢®¨­®¢($200000)',
    '6) ˆ§¬¥­¨âì ¢®¨­®¢($400000)',
    '6) “á¨«¨âì ¢®¨­®¢($100000)');

  WizardPrices: array[1..6] of longint = (
    100000,
    500000,
    200000,
    200000,
    400000,
    100000);

  SpellColors: array[0..7] of string[10] = (
    'Š€‘…',
    '€†…‚…',
    '†…‹’…',
    '‡…‹……',
    'ƒ‹“…',
    '‘ˆ……',
    '”ˆ‹…’‚…',
    '…‹…');

  RitualCosts: array[0..7] of byte = (
    15,
    7,
    10,
    10,
    8,
    11,
    13,
    0);

  SpellEffects: array[0..7] of string[35] = (
    '¥p¥¤ ¥â â¥«  á®§¤ ¢ ¥¬ë¬ ¢®¨­ ¬',
    '¥p¥¤ ¥â ª®«¨ç¥áâ¢® è £®¢ ¢®¨­®¢',
    '¥p¥¤ ¥â ®¡éãî á¨«ã ã¤ p ',
    '¥p¥¤ ¥â ®¡éãî ¢¥«¨ç¨­ã § é¨âë',
    '¥p¥¤ ¥â ª®«¨ç¥áâ¢® ®â¢¥â­ëå ã¤ p®¢',
    '¥p¥¤ ¥â á¯®á®¡­®áâì «¥â âì',
    '¥p¥¤ ¥â á¯®á®¡­®áâì áâp¥«ïâì',
    'Bë§ë¢ ¥â „ãå ˆ’“€‹œƒ Š€ŒŸ');

  GoodsNames: array[1..7] of string[9] = (
    '”“Š’›',
    '‘‹€„‘’ˆ',
    '‚ˆ',
    '€•€’',
    '“Š€˜…ˆŸ',
    '“†ˆ…',
    '†…Œ—“ƒ');

  GoodsBasePrices: array[1..7] of word = (
    100,
    150,
    200,
    150,
    300,
    400,
    500);

  GoodsTownVariations: array[1..5] of array[1..7] of byte = (
    (20, 25, 30, 25, 40, 50, 60),
    (30, 35, 40, 35, 50, 60, 70),
    (40, 45, 50, 45, 60, 70, 80),
    (50, 55, 60, 55, 70, 80, 90),
    (60, 65, 70, 65, 80, 90, 100));

  ShipMenuCaptions: array[boolean] of string[24] = (
    '2) Šã¯¨âì ª®p ¡«ì($500).',
    '2) â¬¥­¨âì ª®p ¡«ì.    ');

  SelectionHighlights: array[boolean] of boolean = (
    false,
    true);

  BattleCellOffsets: array[0..29] of word = (
    1761,
    1773,
    1785,
    1797,
    1809,
    1821,
    6561,
    6573,
    6585,
    6597,
    6609,
    6621,
    11361,
    11373,
    11385,
    11397,
    11409,
    11421,
    16161,
    16173,
    16185,
    16197,
    16209,
    16221,
    20961,
    20973,
    20985,
    20997,
    21009,
    21021);

  HeroRelicPositions: array[2..5] of word = (
    20961,
    20973,
    20997,
    21009);

  WorkshopRelicPositions: array[2..5] of word = (
    11361,
    20985,
    11409,
    1785);

  WorkshopArmyPositions: array[0..4] of word = (
    1822,
    6622,
    11422,
    16222,
    21022);

  DesertRimExtent: byte = 10;

  GrassAttempts: array[0..3] of array[1..5] of word = (
    (0, 3000, 1500, 1000, 1000),
    (0, 2500, 1000, 1000, 1000),
    (0, 2500, 1000, 700, 1000),
    (0, 2500, 800, 700, 1000));

  RiverBudgets: array[0..3] of array[1..5] of word = (
    (1000, 1500, 1200, 1000, 200),
    (1000, 1500, 1000, 800, 200),
    (1000, 2000, 800, 500, 100),
    (1000, 2000, 800, 500, 100));

  ForestAttempts: array[0..3] of array[1..5] of word = (
    (2000, 1000, 0, 500, 200),
    (2500, 1000, 0, 1000, 200),
    (3000, 1500, 0, 1000, 200),
    (3000, 1500, 0, 1000, 200));

  MountainAttempts: array[0..3] of array[1..5] of word = (
    (1000, 500, 600, 0, 0),
    (1000, 500, 800, 0, 0),
    (2000, 1000, 800, 0, 0),
    (2500, 1000, 800, 0, 0));

  SandAttempts: array[0..3] of array[1..5] of word = (
    (600, 100, 200, 300, 0),
    (1000, 500, 800, 500, 0),
    (300, 500, 500, 700, 0),
    (300, 500, 500, 700, 0));

  WanderingArmyBudgets: array[0..3] of array[1..5] of word = (
    (300, 1000, 1500, 5000, 10000),
    (500, 1200, 2000, 5000, 15000),
    (1000, 2000, 5000, 10000, 50000),
    (1000, 2000, 5000, 10000, 65000));

  GuardianDragonCounts: array[0..3] of byte = (
    2,
    5,
    7,
    10);

  InitialWeekLimits: array[0..3] of word = (
    600,
    400,
    300,
    200);

  ScrollChoiceOrder: array[0..13] of byte = (
    1,
    2,
    10,
    0,
    5,
    7,
    11,
    13,
    3,
    8,
    12,
    4,
    6,
    9);

  ScrollChoiceBounds: array[1..5] of byte = (
    59,
    79,
    109,
    139,
    139);

implementation

end.
