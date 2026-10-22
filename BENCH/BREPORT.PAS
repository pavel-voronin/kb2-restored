program BenchReport;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}
const
  Cases = 8;
  Counters = 11;
  MaxSamples = 5;
  PITFrequency = 1193182.0;
type
  TCaseName = string[8];
  TRow = array[1..15] of string[20];
  TTimes = array[1..Cases, 1..MaxSamples] of longint;
  TCounts = array[1..Cases, 1..Counters] of longint;
  THashes = array[1..Cases] of longint;
  TSampleCounts = array[1..Cases] of byte;
  TMemory = array[1..7] of longint;
  TRun = record
    Times: TTimes;
    Counts: TCounts;
    Hashes: THashes;
    Samples: TSampleCounts;
    Memory: TMemory;
  end;
  TMZ = array[0..13] of word;
var
  RefTime, CurTime, RefCount, CurCount: TRun;
  Names: array[1..Cases] of TCaseName;
  I, J: byte;
  RefMedian, CurMedian, Low, High: longint;

procedure Fail(Message: string);
begin
  WriteLn('FAIL: ', Message);
  Halt(1);
end;

function Number(S: string): longint;
var
  Value: longint;
  Error: integer;
begin
  Val(S, Value, Error);
  if Error <> 0 then Fail('Invalid number: ' + S);
  Number := Value;
end;

procedure Parse(Line: string; var Row: TRow);
var
  N, P: byte;
begin
  FillChar(Row, SizeOf(Row), 0);
  N := 1;
  repeat
    P := Pos(',', Line);
    if P = 0 then P := Length(Line) + 1;
    if N > 15 then Fail('CSV has too many columns');
    Row[N] := Copy(Line, 1, P - 1);
    Delete(Line, 1, P);
    Inc(N);
  until Length(Line) = 0;
end;

procedure Load(Name: string; var Run: TRun);
var
  F: text;
  Line: string;
  Row: TRow;
  Index, K, N: byte;
  Value: longint;
  HeapChecked, MemoryRead: boolean;
begin
  FillChar(Run, SizeOf(Run), 0);
  HeapChecked := false;
  MemoryRead := false;
  Assign(F, Name);
  Reset(F);
  ReadLn(F, Line);
  if Copy(Line, 1, 4) <> 'case' then Fail('Bad CSV header: ' + Name);
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Parse(Line, Row);
    if Row[1] = 'memory' then
    begin
      if MemoryRead then Fail('Duplicate memory row');
      for K := 1 to 7 do Run.Memory[K] := Number(Row[K + 2]);
      MemoryRead := true;
    end
    else if Row[1] = 'heapcheck' then
    begin
      if Number(Row[3]) <> 0 then Fail('Temporary heap leak: ' + Name);
      HeapChecked := true;
    end
    else
    begin
      Index := 0;
      for K := 1 to Cases do if Row[1] = Names[K] then Index := K;
      if Index = 0 then Fail('Unknown case: ' + Row[1]);
      Inc(Run.Samples[Index]);
      N := Run.Samples[Index];
      if N > MaxSamples then Fail('Too many samples: ' + Name);
      if Number(Row[2]) <> N then Fail('Sample sequence: ' + Name);
      Run.Times[Index, N] := Number(Row[3]);
      if Run.Times[Index, N] <= 0 then Fail('Nonpositive interval: ' + Name);
      Value := Number(Row[4]);
      if (N > 1) and (Value <> Run.Hashes[Index]) then Fail('Unstable result: ' + Name);
      Run.Hashes[Index] := Value;
      for K := 1 to Counters do
      begin
        Value := Number(Row[K + 4]);
        if (N > 1) and (Value <> Run.Counts[Index, K]) then Fail('Unstable counters: ' + Name);
        Run.Counts[Index, K] := Value;
      end;
    end;
  end;
  Close(F);
  if not HeapChecked or not MemoryRead then Fail('Incomplete run: ' + Name);
  for K := 1 to Cases do if Run.Samples[K] = 0 then Fail('Missing case: ' + Name);
end;

function Median(var Run: TRun; Index: byte; var Low, High: longint): longint;
var
  Sorted: array[1..MaxSamples] of longint;
  A, B, N: byte;
  Swap: longint;
begin
  N := Run.Samples[Index];
  for A := 1 to N do Sorted[A] := Run.Times[Index, A];
  for A := 1 to N do
    for B := A + 1 to N do
      if Sorted[A] > Sorted[B] then
      begin
        Swap := Sorted[A];
        Sorted[A] := Sorted[B];
        Sorted[B] := Swap;
      end;
  Low := Sorted[1];
  High := Sorted[N];
  Median := Sorted[N div 2 + 1];
end;

procedure ImageMemory(Name: string);
var
  F: file;
  Header: TMZ;
  Bytes, HeaderBytes, Minimum: longint;
begin
  Assign(F, Name);
  Reset(F, 1);
  Bytes := FileSize(F);
  BlockRead(F, Header, SizeOf(Header));
  Close(F);
  if Header[0] <> $5A4D then Fail('Not an MZ executable: ' + Name);
  HeaderBytes := longint(Header[4]) * 16;
  Minimum := Bytes - HeaderBytes + longint(Header[5]) * 16 + 256;
  WriteLn(Name, ': file=', Bytes, ' header=', HeaderBytes,
    ' minimum+PSP=', Minimum, ' stack=', Header[8]);
end;

begin
  Names[1] := 'world0';
  Names[2] := 'world1';
  Names[3] := 'world2';
  Names[4] := 'world3';
  Names[5] := 'strikes';
  Names[6] := 'targets';
  Names[7] := 'ai_scene';
  Names[8] := 'tiles';
  Load('REFTIME.CSV', RefTime);
  Load('CURTIME.CSV', CurTime);
  Load('REFCNT.CSV', RefCount);
  Load('CURCNT.CSV', CurCount);
  for I := 1 to Cases do
  begin
    if RefTime.Samples[I] <> CurTime.Samples[I] then Fail('Different sample counts');
    if (RefTime.Hashes[I] <> CurTime.Hashes[I]) or
       (RefTime.Hashes[I] <> RefCount.Hashes[I]) or
       (RefTime.Hashes[I] <> CurCount.Hashes[I]) then Fail('Result differs: ' + Names[I]);
    for J := 1 to Counters do
    begin
      if RefCount.Counts[I, J] <> CurCount.Counts[I, J] then Fail('Work differs: ' + Names[I]);
      if (RefTime.Counts[I, J] <> 0) or (CurTime.Counts[I, J] <> 0) then
        Fail('Timing run contains counters');
    end;
  end;
  for I := 1 to 5 do
    if RefCount.Memory[I] <> CurCount.Memory[I] then Fail('Game memory allocation differs');
  WriteLn('PASS: all result fingerprints, work counts and game allocations agree.');
  WriteLn('Seconds: median [minimum..maximum]. Positive delta means slower.');
  for I := 1 to Cases do
  begin
    RefMedian := Median(RefTime, I, Low, High);
    Write(Names[I]:8, ' ref ', RefMedian / PITFrequency:9:6,
      ' [', Low / PITFrequency:9:6, '..', High / PITFrequency:9:6, ']');
    CurMedian := Median(CurTime, I, Low, High);
    WriteLn(' cur ', CurMedian / PITFrequency:9:6,
      ' [', Low / PITFrequency:9:6, '..', High / PITFrequency:9:6, '] ',
      (CurMedian / RefMedian - 1) * 100:7:3, '%');
  end;
  WriteLn('Work: strikes damage targets cells cost frames framecells RNG tiles copybytes phases');
  for I := 1 to Cases do
  begin
    Write(Names[I]:8);
    for J := 1 to Counters do Write(' ', RefCount.Counts[I, J]);
    WriteLn;
  end;
  WriteLn('Game record: ', RefCount.Memory[1], ' bytes');
  WriteLn('Heap: requested=', RefCount.Memory[2], ' actual=', RefCount.Memory[3],
    ' peak=', RefCount.Memory[4], ' allocations=', RefCount.Memory[5]);
  WriteLn('The heap above covers graphics startup, not all possible game states.');
  WriteLn('Release executable memory (heap excluded):');
  ImageMemory('REFGAME.EXE');
  ImageMemory('CURGAME.EXE');
end.
