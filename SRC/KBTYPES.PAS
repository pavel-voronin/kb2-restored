unit KBTypes;
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

  TPosition = packed record
    X, Y: byte
  end;

  TSignedPosition = packed record
    X, Y: shortint
  end;

  TContract = packed record
    Island, Slot: byte
  end;

  TRelic = packed record
    Artwork: byte;
    Owned: boolean
  end;

  TArmyStack = packed record
    Species: byte;
    Count: word
  end;

  TWanderingArmy = packed record
    X, Y: byte;
    Species: array[0..4] of byte;
    Counts: array[0..4] of word;
  end;

  TCastle = packed record
    X, Y, Name: byte;
    Owned: boolean;
    Species: array[0..4] of byte;
    Counts: array[0..4] of word;
    Value: longint;
  end;

  TTown = packed record
    X, Y, Name, Scroll: byte;
    Workers: array[1..4] of byte;
  end;

  TDwelling = packed record
    X, Y, Species: byte;
    Count: word
  end;

type
  PRoamingActor = ^TRoamingActor;
  TRoamingActor = packed record
    X, Y, Age: byte
  end;

  TReportSpecies = array[0..4] of byte;
  TReportCounts = array[0..4] of word;
  TTownVisitState = packed record
    Caption: string[80];
    LoadedTownArtwork: boolean;
    Slot: byte;
    JournalIndex: shortint;
  end;

implementation

end.
