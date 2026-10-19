program ResourcePacker;
{ Собирает PIC и KB2.FNT из PCX в ART по списку PACK.LST.
  Запускать из SRC; готовые файлы записываются в DIST. }
{$G+,R-,S-,I+,A+}
{$M 16384,0,655360}

type
  TPlane = array[0..27999] of byte;
  PPlane = ^TPlane;
  TBuffer = array[0..4095] of byte;
  TPcxHeader = packed record
    Manufacturer, Version, Encoding, BitsPerPixel: byte;
    XMin, YMin, XMax, YMax, HRes, VRes: word;
    Palette: array[0..47] of byte;
    Reserved, Planes: byte;
    BytesPerLine, PaletteType: word;
    Filler: array[1..58] of byte;
  end;

const
  EgaPalette: array[0..47] of byte = (
    0, 0, 0, 0, 0, 170, 0, 170, 0, 0, 170, 170,
    170, 0, 0, 170, 0, 170, 170, 85, 0, 170, 170, 170,
    85, 85, 85, 85, 85, 255, 85, 255, 85, 85, 255, 255,
    255, 85, 85, 255, 85, 255, 255, 255, 85, 255, 255, 255);

var
  Image: array[0..3] of PPlane;
  Width, Height, Stride, PlaneSize: word;
  InputFile, OutputFile: file;
  InputBuffer, OutputBuffer: TBuffer;
  InputCount, InputIndex, OutputCount: word;
  RunCount, RunValue: byte;
  List: text;
  Line, Stem, Kind: string;
  Count, ParseError, I: integer;

procedure Fail(Message: string);
begin
  WriteLn('ERROR: ', Message);
  Halt(1);
end;

function ReadByte: byte;
begin
  if InputIndex = InputCount then
  begin
    BlockRead(InputFile, InputBuffer, SizeOf(InputBuffer), InputCount);
    InputIndex := 0;

    if InputCount = 0 then Fail('Truncated PCX');
  end;

  ReadByte := InputBuffer[InputIndex];
  Inc(InputIndex);
end;

function ReadPixelByte: byte;
var
  ValueByte: byte;

begin
  if RunCount = 0 then
  begin
    ValueByte := ReadByte;

    if ValueByte and $C0 = $C0 then
    begin
      RunCount := ValueByte and $3F;

      if RunCount = 0 then Fail('Invalid PCX run');
      RunValue := ReadByte;
    end
    else
    begin
      RunCount := 1;
      RunValue := ValueByte;
    end;
  end;

  ReadPixelByte := RunValue;
  Dec(RunCount);
end;

procedure LoadPcx(Name: string);
var
  Header: TPcxHeader;
  P, Y, X: word;
  ValueByte: byte;

begin
  Assign(InputFile, Name);
  Reset(InputFile, 1);
  BlockRead(InputFile, Header, SizeOf(Header));

  if (Header.Manufacturer <> 10) or (Header.Encoding <> 1) or
     (Header.BitsPerPixel <> 1) or (Header.Planes <> 4) then Fail('Use 16-color planar PCX');
  if (Header.XMax < Header.XMin) or (Header.YMax < Header.YMin) then Fail('Invalid PCX dimensions');
  Width := Header.XMax - Header.XMin + 1;
  Height := Header.YMax - Header.YMin + 1;

  if (Width > 640) or (Height > 350) or (Width mod 8 <> 0) then Fail('PCX dimensions');
  Stride := Width div 8;
  if (Header.BytesPerLine < Stride) or (Header.BytesPerLine > 1024) then Fail('PCX stride');

  for P := 0 to 47 do
    if Header.Palette[P] <> EgaPalette[P] then Fail('PCX palette must be standard EGA');
  PlaneSize := Stride * Height;

  for P := 0 to 3 do GetMem(Image[P], PlaneSize);
  InputCount := 0;
  InputIndex := 0;
  RunCount := 0;

  for Y := 0 to Height - 1 do
    for P := 0 to 3 do
      for X := 0 to Header.BytesPerLine - 1 do
      begin
        ValueByte := ReadPixelByte;

        { В PCX плоскости идут от младшего бита цвета, а в PIC от старшего. }
        if X < Stride then Image[3 - P]^[Y * Stride + X] := ValueByte;
      end;

  if RunCount <> 0 then Fail('PCX run exceeds image');
  if FilePos(InputFile) - InputCount + InputIndex <> FileSize(InputFile) then
    Fail('Unexpected data after PCX image');
  Close(InputFile);
end;

procedure FreeImage;
var
  P: word;

begin
  for P := 0 to 3 do FreeMem(Image[P], PlaneSize);
end;

procedure Flush;
begin
  if OutputCount <> 0 then BlockWrite(OutputFile, OutputBuffer, OutputCount);
  OutputCount := 0;
end;

procedure PutByte(ValueByte: byte);
begin
  OutputBuffer[OutputCount] := ValueByte;
  Inc(OutputCount);

  if OutputCount = SizeOf(OutputBuffer) then Flush;
end;

procedure PutWord(W: word);
begin
  PutByte(Lo(W));
  PutByte(Hi(W));
end;

procedure OpenOutput(Name: string);
begin
  Assign(OutputFile, Name);
  Rewrite(OutputFile, 1);
  OutputCount := 0;
end;

procedure CloseOutput;
begin
  Flush;
  Close(OutputFile);
end;

procedure PackScreen(Stem: string);
var
  P, Position, Last, J, N: word;
  Size: longint;
  ValueByte: byte;

begin
  if (Width <> 640) or (Height <> 350) then Fail('Screen must be 640x350');
  OpenOutput('DIST\' + Stem + '.PIC');

  for P := 0 to 3 do
  begin
    Position := 0;
    Size := 0;

    while Position < 28000 do
    begin
      ValueByte := Image[P]^[Position];
      Last := Position + 1;

      if (ValueByte = 0) or (ValueByte = 255) then
      begin
        while (Last < 28000) and (Image[P]^[Last] = ValueByte) do Inc(Last);
        Inc(Size, 3);
      end
      else Inc(Size);
      Position := Last;
    end;

    if Size >= 28000 then
    begin
      PutWord(28000);

      for J := 0 to 27999 do PutByte(Image[P]^[J]);
    end
    else
    begin
      PutWord(Size);
      Position := 0;

      while Position < 28000 do
      begin
        ValueByte := Image[P]^[Position];
        Last := Position + 1;
        PutByte(ValueByte);

        if (ValueByte = 0) or (ValueByte = 255) then
        begin
          while (Last < 28000) and (Image[P]^[Last] = ValueByte) do Inc(Last);
          N := Last - Position;
          PutWord(N);
        end;

        Position := Last;
      end;
    end;
  end;

  CloseOutput;
end;

procedure PackTiles(Stem: string; Count: word);
var
  Frame, P, Y, X, Position: word;

begin
  if (Width <> 384) or (Height <> ((Count + 3) div 4) * 60) or (Count = 0) then
    Fail('Tile atlas dimensions/count');
  OpenOutput('DIST\' + Stem + '.PIC');

  for Frame := 0 to Count - 1 do
    for P := 0 to 3 do
      for Y := 0 to 59 do
      begin
        Position := ((Frame div 4) * 60 + Y) * Stride + (Frame mod 4) * 12;

        for X := 0 to 11 do PutByte(Image[P]^[Position + X]);
      end;

  CloseOutput;
end;

procedure PackFont;
var
  N, Y, P, Position: word;
  ValueByte: byte;

begin
  if (Width <> 128) or (Height <> 120) then Fail('Font must be 128x120');
  OpenOutput('DIST\KB2.FNT');

  for N := 0 to 239 do
    for Y := 0 to 7 do
    begin
      Position := ((N div 16) * 8 + Y) * Stride + N mod 16;
      ValueByte := Image[0]^[Position];

      for P := 1 to 3 do if Image[P]^[Position] <> ValueByte then Fail('Font must be black/white');
      PutByte(ValueByte);
    end;

  CloseOutput;
end;

function Token(var RemainingText: string): string;
var
  Position: byte;

begin
  while (Length(RemainingText) > 0) and (RemainingText[1] = ' ') do Delete(RemainingText, 1, 1);
  Position := Pos(' ', RemainingText);

  if Position = 0 then
  begin
    Token := RemainingText;
    RemainingText := ''
  end
  else
  begin
    Token := Copy(RemainingText, 1, Position - 1);
    Delete(RemainingText, 1, Position)
  end;
end;

begin
  Assign(List, 'PACK.LST');
  Reset(List);

  while not Eof(List) do
  begin
    ReadLn(List, Line);

    if Line <> '' then
    begin
      Kind := Token(Line);
      Stem := Token(Line);
      Val(Token(Line), Count, ParseError);

      if ParseError <> 0 then Fail('PACK.LST count');
      WriteLn('Packing ', Stem);
      LoadPcx('ART\' + Stem + '.PCX');

      if Kind = 'S' then PackScreen(Stem)
      else if Kind = 'T' then PackTiles(Stem, Count)
      else if Kind = 'F' then PackFont
      else Fail('PACK.LST kind');
      FreeImage;
    end;
  end;

  Close(List);
  WriteLn('Resources built.');
end.
