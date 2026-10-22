program Regression;
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}

uses KBGen, KBRandom, Crt, KBTypes, KBState, KBTables, KBWorld, KBAdvent, KBStart, KBSave;

procedure RunRegression;
const
  ExpectedChecksums: array[0..3] of word = (60011, 27308, 11347, 7659);
type
  TBuffer = array[1..512] of byte;
var
  Level: byte;
  OriginalGold: longint;
  TestLog: text;
  Name: string[12];
  SourceFile, CopyFile: file;
  First, Second: TBuffer;
  ReadFirst, ReadSecond, I, BitIndex, Checksum: word;

begin
  Assign(TestLog, 'REGRESS.LOG');
  Rewrite(TestLog);
{$IFDEF STRUCTURED}
  if (SizeOf(TCampaignFlags) <> 21814) or
     (SizeOf(TCampaignState) <> 46816) or (LegacySaveBytes <> 27729) then Halt(6);
{$ENDIF}
  InitializeRuntime;
  for Level := 0 to 3 do
  begin
    UseRandomSeed(12345 + Level);
    PrepareCampaign(Level);
    GenerateWorld(Level);
    PlaceInitialHero(Level);
    PrepareSave;
    Str(Level, Name);
    Game.Runtime.DataFileName := 'L' + Name + '.DAT';
    WriteCampaign;
    OriginalGold := Game.Campaign.Gold;
    Game.Campaign.Gold := -1;
    ReadCampaign;
    if Game.Campaign.Gold <> OriginalGold then Halt(1);
    Game.Runtime.DataFileName := 'R' + Name + '.DAT';
    WriteCampaign;
    Assign(SourceFile, 'L' + Name + '.DAT');
    Assign(CopyFile, 'R' + Name + '.DAT');
    Reset(SourceFile, 1);
    Reset(CopyFile, 1);
    if (FileSize(SourceFile) <> 27729) or
       (FileSize(CopyFile) <> FileSize(SourceFile)) then Halt(2);
    Checksum := $FFFF;
    repeat
      BlockRead(SourceFile, First, SizeOf(First), ReadFirst);
      BlockRead(CopyFile, Second, SizeOf(Second), ReadSecond);
      if ReadFirst <> ReadSecond then Halt(3);
      for I := 1 to ReadFirst do
      begin
        if First[I] <> Second[I] then Halt(4);
        Checksum := Checksum xor (word(First[I]) shl 8);
        for BitIndex := 1 to 8 do
          if Checksum and $8000 <> 0 then
            Checksum := (Checksum shl 1) xor $1021
          else Checksum := Checksum shl 1;
      end;
    until ReadFirst = 0;
    if Checksum <> ExpectedChecksums[Level] then Halt(5);
    Close(SourceFile);
    Close(CopyFile);
    WriteLn(TestLog, 'Level ', Level, ': 27729 bytes, CRC16 ', Checksum,
      ', save/load OK');
    if ParamStr(1) <> '/KEEP' then
    begin
      Erase(SourceFile);
      Erase(CopyFile);
    end;
  end;
  WriteLn(TestLog, 'PASS');
  Close(TestLog);
end;

begin
  RunRegression;
end.
