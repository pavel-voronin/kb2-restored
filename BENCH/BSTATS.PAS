unit BStats;
{$G+,R-,S-,I+,A+}
interface
const
  CStrikes = 1;
  CDamage = 2;
  CTargets = 3;
  CTargetCells = 4;
  CCostCells = 5;
  CFrameCalls = 6;
  CFrameCells = 7;
  CRandom = 8;
  CTiles = 9;
  CCopyBytes = 10;
  CEnemyPhases = 11;
  CounterCount = 11;
var
  Counting: boolean;
  Counts: array[1..CounterCount] of longint;
  HeapRequested, HeapActual, HeapPeak: longint;
  AllocationCount: longint;
procedure ClearCounts;
procedure Bump(Kind: byte; Amount: longint);
function BenchRandom(Limit: word): word;
procedure BenchGetMem(var P: pointer; Bytes: word);
procedure BenchFreeMem(P: pointer; Bytes: word);
function Digest(var Data; Bytes: word): longint;
function VideoDigest: longint;
function EGAMemoryKB: word;
implementation
procedure ClearCounts;
begin
  Counting := true;
  FillChar(Counts, SizeOf(Counts), 0);
end;
procedure Bump(Kind: byte; Amount: longint);
begin
  if Counting then Inc(Counts[Kind], Amount);
end;
function BenchRandom(Limit: word): word;
begin
  if Counting then Inc(Counts[CRandom]);
  BenchRandom := Random(Limit);
end;
procedure BenchGetMem(var P: pointer; Bytes: word);
var
  Before: longint;
begin
  Before := MemAvail;
  GetMem(P, Bytes);
  Inc(AllocationCount);
  Inc(HeapRequested, Bytes);
  Inc(HeapActual, Before - MemAvail);
  if HeapActual > HeapPeak then HeapPeak := HeapActual;
end;
procedure BenchFreeMem(P: pointer; Bytes: word);
var
  Before: longint;
begin
  Before := MemAvail;
  FreeMem(P, Bytes);
  Dec(HeapRequested, Bytes);
  Dec(HeapActual, MemAvail - Before);
end;
function Digest(var Data; Bytes: word): longint;
type
  TBytes = array[0..65519] of byte;
  PBytes = ^TBytes;
var
  I: word;
  Value: longint;
begin
  Value := 0;
  for I := 0 to Bytes - 1 do
    Value := (Value shl 1) xor (Value shr 31) xor PBytes(@Data)^[I];
  Digest := Value;
end;
{ Читаем четыре плоскости скрытой страницы, за пределами замера. }
function VideoDigest: longint;
var
  Plane, OldPlane: byte;
  Value: longint;
begin
  Port[$3CE] := 4;
  OldPlane := Port[$3CF];
  Value := 0;
  for Plane := 0 to 3 do
  begin
    Port[$3CE] := 4;
    Port[$3CF] := Plane;
    Value := (Value shl 1) xor (Value shr 31) xor Digest(Mem[$A000:$8000], 28000);
  end;
  Port[$3CE] := 4;
  Port[$3CF] := OldPlane;
  VideoDigest := Value;
end;

{ BIOS возвращает число дополнительных блоков по 64 КиБ. }
function EGAMemoryKB: word; assembler;
asm
  mov ah, $12
  mov bl, $10
  int $10
  inc bl
  mov al, 64
  mul bl
end;

begin
  ClearCounts;
  HeapRequested := 0;
  HeapActual := 0;
  HeapPeak := 0;
  AllocationCount := 0;
end.
