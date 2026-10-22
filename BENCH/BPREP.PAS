program PrepareBench;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}
uses Dos;
const
  Capacity = 65520;
  NL = #13#10;
type
  TBuffer = array[1..Capacity] of char;
  PBuffer = ^TBuffer;
var
  Source, Scratch, Work: PBuffer;
  SourceSize, WorkSize: word;
  RefRoot, CurrentRoot, Target: string;
  IsReference, Patch: boolean;

procedure Fail(Message: string);
begin
  WriteLn(Message);
  Halt(1);
end;

function Locate(P: PBuffer; Length: word; Text: string; Start: word): word;
var
  I, J: word;
  Match: boolean;
begin
  Locate := 0;
  if Length < System.Length(Text) then Exit;
  I := Start;
  while I <= Length - System.Length(Text) + 1 do
  begin
    Match := true;
    for J := 1 to System.Length(Text) do
      if P^[I + J - 1] <> Text[J] then Match := false;
    if Match then
    begin
      Locate := I;
      Exit;
    end;
    Inc(I);
  end;
end;

procedure Load(Name: string; P: PBuffer; var Length: word);
var
  F: file;
  Count: word;
begin
  Assign(F, Name);
  Reset(F, 1);
  if FileSize(F) > Capacity then Fail('Source too large: ' + Name);
  Length := FileSize(F);
  BlockRead(F, P^, Length, Count);
  Close(F);
  if Count <> Length then Fail('Short read: ' + Name);
end;

procedure Save(Name: string; P: PBuffer; Length: word);
var
  F: file;
  Count: word;
begin
  Assign(F, Name);
  Rewrite(F, 1);
  BlockWrite(F, P^, Length, Count);
  Close(F);
  if Count <> Length then Fail('Short write: ' + Name);
end;

procedure ReplaceText(Old, NewText: string);
var
  I, J, Match, OutSize: word;
  Swap: PBuffer;
begin
  I := 1;
  OutSize := 0;
  while I <= SourceSize do
  begin
    Match := Locate(Source, SourceSize, Old, I);
    if Match = 0 then Match := SourceSize + 1;
    while I < Match do
    begin
      Inc(OutSize);
      if OutSize > Capacity then Fail('Transformed source too large');
      Scratch^[OutSize] := Source^[I];
      Inc(I);
    end;
    if I <= SourceSize then
    begin
      for J := 1 to Length(NewText) do
      begin
        Inc(OutSize);
        if OutSize > Capacity then Fail('Transformed source too large');
        Scratch^[OutSize] := NewText[J];
      end;
      Inc(I, Length(Old));
    end;
  end;
  Swap := Source;
  Source := Scratch;
  Scratch := Swap;
  SourceSize := OutSize;
end;

procedure Splice(Position, RemoveBytes: word; Insert: PBuffer; Bytes: word);
var
  NewSize: longint;
begin
  NewSize := longint(SourceSize) - RemoveBytes + Bytes;
  if NewSize > Capacity then Fail('Splice too large');
  Move(Source^[1], Scratch^[1], Position - 1);
  if Bytes > 0 then Move(Insert^[1], Scratch^[Position], Bytes);
  Move(Source^[Position + RemoveBytes], Scratch^[Position + Bytes],
    SourceSize - Position - RemoveBytes + 1);
  Move(Scratch^[1], Source^[1], NewSize);
  SourceSize := NewSize;
end;

procedure InsertString(Position: word; Text: string);
var
  B: PBuffer;
  I: word;
begin
  GetMem(B, Length(Text));
  for I := 1 to Length(Text) do B^[I] := Text[I];
  Splice(Position, 0, B, Length(Text));
  FreeMem(B, Length(Text));
end;

procedure Hook(Name, Code: string);
var
  Position, Body: word;
begin
  Position := Locate(Source, SourceSize, Name, 1);
  if Position = 0 then Exit;
  if Locate(Source, SourceSize, 'implementation', 1) <> 0 then
  begin
    Position := Locate(Source, SourceSize, Name,
      Locate(Source, SourceSize, 'implementation', 1));
    if Position = 0 then Exit;
  end;
  Body := Locate(Source, SourceSize, 'begin' + NL, Position);
  if Body = 0 then Fail('No body: ' + Name);
  InsertString(Body + 7, '{$IFDEF BCOUNT}' + Code + '{$ENDIF}' + NL);
end;

procedure Imports;
var
  Position, UsesPosition: word;
  Clause: string;
begin
  Clause := 'BStats, BClock';
  if Locate(Source, SourceSize, 'KBRandom', 1) = 0 then Clause := Clause + ', KBRandom';
  if Locate(Source, SourceSize, 'unit KBBattle;', 1) <> 0 then
    if IsReference then Clause := Clause + ', KBWorld'
    else Clause := Clause + ', KBGen, KBBDmg';
  Position := Locate(Source, SourceSize, 'implementation', 1);
  if Position = 0 then Position := 1;
  UsesPosition := Locate(Source, SourceSize, 'uses ', Position);
  if UsesPosition > 0 then InsertString(UsesPosition + 5, Clause + ', ')
  else InsertString(Position + 14, NL + 'uses ' + Clause + ';' + NL);
end;

procedure Instrument;
var
  Start, Finish, Position: word;
begin
  ReplaceText('Random(', 'BenchRandom(');
  ReplaceText('GetMem(', '{$IFDEF BCOUNT}BenchGetMem{$ELSE}GetMem{$ENDIF}(');
  ReplaceText('FreeMem(', '{$IFDEF BCOUNT}BenchFreeMem{$ELSE}FreeMem{$ENDIF}(');
  ReplaceText('BenchRandom(', '{$IFDEF BCOUNT}BenchRandom{$ELSE}Random{$ENDIF}(');
  if IsReference then ReplaceText('Randomize;', 'RandomizeGame;');
  Hook('function ResolveStrike(', 'Bump(CStrikes, 1);');
  Hook('function ApplyDamage(', 'Bump(CDamage, 1);');
  Hook('function FindAdjacent(', 'Bump(CTargets, 1);');
  Hook('procedure DrawPictureTile(', 'Bump(CTiles, 1);');
  Hook('procedure CopyRecord(', 'Bump(CCopyBytes, Bytes);');
  Hook('procedure FrameTerrain(', 'Bump(CFrameCalls, 1);');
  ReplaceText('  while KeyPressed do ',
    '  {$IFDEF BCOUNT}Bump(CEnemyPhases, 1);{$ENDIF}' + NL + '  while KeyPressed do ');
  ReplaceText('      TX := X + DX;',
    '      {$IFDEF BCOUNT}Bump(CTargetCells, 1);{$ENDIF}' + NL + '      TX := X + DX;');
  ReplaceText('      EnemyAI.Distance := Abs(',
    '      {$IFDEF BCOUNT}Bump(CCostCells, 1);{$ENDIF}' + NL + '      EnemyAI.Distance := Abs(');
  Start := Locate(Source, SourceSize, 'procedure FrameTerrain(', 1);
  if Start > 0 then
  begin
    Position := Locate(Source, SourceSize, '    for Y := 1 to 64 do' + NL, Start);
    Finish := Locate(Source, SourceSize, 'procedure GenerateContracts;', Start);
    if (Position = 0) or (Finish = 0) then Fail('FrameTerrain layout changed');
    InsertString(Position + Length('    for Y := 1 to 64 do' + NL),
      '      {$IFDEF BCOUNT}begin Bump(CFrameCells, 1);{$ENDIF}' + NL);
    Finish := Locate(Source, SourceSize, 'procedure GenerateContracts;', Start);
    Position := Finish - 1;
    while Source^[Position] <> ';' do Dec(Position);
    while Source^[Position] <> 'e' do Dec(Position);
    InsertString(Position, '    {$IFDEF BCOUNT}end;{$ENDIF}' + NL);
  end;
end;

procedure WrapLines;
var
  First, Finish, Scan, BreakAt, OutSize, I: word;
  Quoted, Comment: boolean;
  Swap: PBuffer;
procedure Emit(C: char);
begin
  Inc(OutSize);
  if OutSize > Capacity then Fail('Wrapped source too large');
  Scratch^[OutSize] := C;
end;
begin
  First := 1;
  OutSize := 0;
  while First <= SourceSize do
  begin
    Finish := First;
    while (Finish <= SourceSize) and (Source^[Finish] <> #13) do Inc(Finish);
    while Finish - First > 118 do
    begin
      BreakAt := 0;
      Quoted := false;
      Comment := false;
      for Scan := First to First + 115 do
      begin
        if (Source^[Scan] = #39) and not Comment then Quoted := not Quoted;
        if (Source^[Scan] = '{') and not Quoted then Comment := true;
        if (Source^[Scan] = '}') and not Quoted then Comment := false;
        if (Source^[Scan] = ' ') and not Quoted and not Comment and
           (Scan > First + 4) then BreakAt := Scan;
      end;
      if BreakAt = 0 then Fail('Cannot wrap generated line');
      for I := First to BreakAt - 1 do Emit(Source^[I]);
      Emit(#13);
      Emit(#10);
      for I := 1 to 4 do Emit(' ');
      First := BreakAt + 1;
    end;
    for I := First to Finish - 1 do Emit(Source^[I]);
    if Finish <= SourceSize then
    begin
      Emit(#13);
      Emit(#10);
    end;
    First := Finish + 2;
  end;
  Swap := Source;
  Source := Scratch;
  Scratch := Swap;
  SourceSize := OutSize;
end;

procedure Transform(Name, Destination: string);
var
  Position: word;
  Saved: PBuffer;
  SavedSize: word;
begin
  Load(Name, Source, SourceSize);
  if Pos('.PAS', Destination) > 0 then Imports;
  Instrument;
  if IsReference and (Locate(Source, SourceSize, 'unit KBBattle;', 1) <> 0) then
    InsertString(Length('unit KBBattle;') + 1, NL + '{$DEFINE BREF}');
  if (IsReference and (Pos('COMBAT.INC', Destination) > 0)) or
     (not IsReference and (Pos('KBBATTLE.PAS', Destination) > 0)) then
  begin
    if IsReference then Position := Locate(Source, SourceSize, 'begin' + NL + '  { ', 1)
    else Position := Locate(Source, SourceSize, 'begin' + NL + '  { ',
      Locate(Source, SourceSize, 'implementation', 1));
    if Position = 0 then Fail('Battle entry changed');
    Splice(Position, 0, Work, WorkSize);
    Position := Locate(Source, SourceSize, 'begin' + NL + '  { ', Position + WorkSize);
    InsertString(Position + 7, '  RunBenchmarks;' + NL + '  asm mov ax, 3; int 10h end;' + NL + '  Halt;' + NL);
  end;
  if Pos('KB2.PAS', Destination) > 0 then
  begin
    if IsReference then
    begin
      Position := Locate(Source, SourceSize, 'label' + NL + '  AdventureLoop, InputReady;', 1);
      if Position > 0 then Splice(Position, Length('label' + NL + '  AdventureLoop, InputReady;' + NL), Work, 0);
      Position := Locate(Source, SourceSize, 'begin' + NL + '  SetGraphicsMode(1);', 1);
      if Position = 0 then Fail('Reference main entry changed');
      SourceSize := Position - 1;
      InsertString(Position, 'begin' + NL + '  InitializeRuntime;' + NL + '  SetGraphicsMode(1);' + NL +
        '  LoadTitle;' + NL + '  LoadGameArtwork;' + NL + '  Game.SoundDisabled := true;' + NL +
        '  Battle(@Game.GuardianSpecies, @Game.GuardianCounts, 0);' + NL + 'end.' + NL);
    end
    else
    begin
      Load('BENCH\BENTRY.PAS', Source, SourceSize);
    end;
  end;
  WrapLines;
  Save(Destination, Source, SourceSize);
end;

procedure CopyFile(Name, Destination: string);
var
  InputFile, OutputFile: file;
  ReadBytes, Written: word;
begin
  Assign(InputFile, Name);
  Reset(InputFile, 1);
  Assign(OutputFile, Destination);
  Rewrite(OutputFile, 1);
  repeat
    BlockRead(InputFile, Source^, 4096, ReadBytes);
    BlockWrite(OutputFile, Source^, ReadBytes, Written);
    if Written <> ReadBytes then Fail('Copy failed: ' + Name);
  until ReadBytes = 0;
  Close(InputFile);
  Close(OutputFile);
end;

procedure CopySources(Root, Destination: string);
var
  Search: SearchRec;
begin
  FindFirst(Root + '\SRC\*.*', AnyFile, Search);
  while DosError = 0 do
  begin
    if (Pos('.PAS', Search.Name) > 0) or (Pos('.INC', Search.Name) > 0) then
      if Patch and (Search.Name <> 'KBRANDOM.PAS') then
        Transform(Root + '\SRC\' + Search.Name, Destination + '\' + Search.Name)
      else CopyFile(Root + '\SRC\' + Search.Name, Destination + '\' + Search.Name);
    FindNext(Search);
  end;
end;

procedure MakeDirectory(Name: string);
var
  Search: SearchRec;
begin
  FindFirst(Name, Directory, Search);
  if DosError <> 0 then MkDir(Name);
end;

var
  Search: SearchRec;
  I: byte;
  Copies: array[1..2] of string[3];
begin
  if ParamCount < 2 then Fail('Usage: BPREP /COPY|/PATCH reference-root');
  Patch := ParamStr(1) = '/PATCH';
  RefRoot := ParamStr(2);
  while (Length(RefRoot) > 0) and (RefRoot[Length(RefRoot)] = '\') do Dec(RefRoot[0]);
  CurrentRoot := '.';
  FindFirst(RefRoot + '\SRC\STARTUP.INC', AnyFile, Search);
  if DosError <> 0 then Fail('Expected historical reference sources, not continued.');
  GetMem(Source, Capacity);
  GetMem(Scratch, Capacity);
  GetMem(Work, Capacity);
  Load('BENCH\BWORK.INC', Work, WorkSize);
  MakeDirectory('BENCH\WORK');
  MakeDirectory('BENCH\WORK\REF');
  MakeDirectory('BENCH\WORK\CUR');
  MakeDirectory('BENCH\WORK\DATA');
  IsReference := false;
  CopySources(CurrentRoot, 'BENCH\WORK\CUR');
  IsReference := true;
  { Имена полей и контекст боя в шаблоне соответствуют continued. }
  Move(Work^[1], Source^[1], WorkSize);
  SourceSize := WorkSize;
  ReplaceText('Game.Campaign.Flags.', 'Game.');
  ReplaceText('Game.Campaign.', 'Game.');
  ReplaceText('Game.Runtime.', 'Game.');
  ReplaceText('Game.World.', 'Game.');
  ReplaceText('ResolveStrike(Combat, ', 'ResolveStrike(');
  ReplaceText('EnemyPhase(Combat)', 'EnemyPhase');
  Move(Source^[1], Work^[1], SourceSize);
  WorkSize := SourceSize;
  CopySources(RefRoot, 'BENCH\WORK\REF');
  Copies[1] := 'REF';
  Copies[2] := 'CUR';
  for I := 1 to 2 do
  begin
    CopyFile('BENCH\BCLOCK.PAS', 'BENCH\WORK\' + Copies[I] + '\BCLOCK.PAS');
    CopyFile('BENCH\BSTATS.PAS', 'BENCH\WORK\' + Copies[I] + '\BSTATS.PAS');
    CopyFile('SRC\KBRANDOM.PAS', 'BENCH\WORK\' + Copies[I] + '\KBRANDOM.PAS');
  end;
  FindFirst('SRC\DIST\*.PIC', AnyFile, Search);
  while DosError = 0 do
  begin
    CopyFile('SRC\DIST\' + Search.Name, 'BENCH\WORK\DATA\' + Search.Name);
    FindNext(Search);
  end;
  CopyFile('SRC\DIST\KB2.FNT', 'BENCH\WORK\DATA\KB2.FNT');
  WriteLn('Prepared isolated benchmark sources.');
end.
