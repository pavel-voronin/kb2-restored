unit KBMap;
{$G+,R-,S-,I+,A+}

interface

procedure MapVisit(Island: byte);

implementation

uses KBReport, KBTables, KBUI, KBGfx, KBInput, Crt, KBState;

procedure MapVisit(Island: byte);
label
  Render;

const
  XCaption = 'X:';
  YCaption = 'Y:';
  NorthCaption = 'ë';
  SouthCaption = 'û';
  WestCaption = 'á';
  EastCaption = 'B';

var
  X, Y: word;
  Phase: byte;
  CursorOffset, CursorOldColor: word;
  RevealAll: boolean;

procedure MapDot(Update: byte; X, Y, Color: byte; var CursorOffset: word; var CursorOldColor: byte);
begin
  asm
    test byte ptr [bp+$14], $ff
    jne @Paint
    mov di, $c8f
    mov al, byte ptr [bp+$12]
    shr al, 1
    xor ah, ah
    add di, ax
    mov al, byte ptr [bp+$10]
    mov dx, $f0
    mul dx
    add di, ax
    les bx, [bp+$a]
    mov es:[bx], di
    les bx, [bp+6]
    mov al, byte ptr [bp+$e]
    mov es:[bx], al
    jmp @Done

  @Paint:
    mov bh, 8

  @Plane:
    les si, [bp+$a]
    mov di, es:[si]
    mov dx, $3c4
    mov al, 2
    mov ah, bh
    out dx, ax
    mov dx, $4f
    mov cx, 3
    les si, [bp+6]
    test byte ptr es:[si], bh
    je @Dark
    mov al, $f0
    jmp @Foreground

  @Dark:
    xor al, al

  @Foreground:
    test byte ptr [bp+$e], bh
    je @LowDark
    or al, $f
    jmp @Store

  @LowDark:
    and al, $f0

  @Store:
    mov si, $a000
    mov es, si

  @Pixel:
    stosb
    add di, dx
    loop @Pixel
    shr bh, 1
    jne @Plane

  @Done:
  end;
end;

procedure PrintMap;

const
  Name1 = 'êAÇçéãÖëúÖ';
  Name2 = 'áÄÅéãéíàü';
  Name3 = 'íÄâÉÄçàü';
  Name4 = 'Äãúèàü';
  Name5 = 'CÄïÄêàü';

var
  X, Y, I, Kind: byte;
  K: word;

begin
  {$I-} Write(Game.Runtime.Lst,#7); {$I+}
  if IOResult = 0 then
  begin
    Write(Game.Runtime.Lst, #14);

    case Island of
      1: WriteLn(Game.Runtime.Lst, Name1);
      2: WriteLn(Game.Runtime.Lst, Name2);
      3: WriteLn(Game.Runtime.Lst, Name3);
      4: WriteLn(Game.Runtime.Lst, Name4);
      5: WriteLn(Game.Runtime.Lst, Name5);
    end;

    WriteLn(Game.Runtime.Lst);
    Write(Game.Runtime.Lst, #27, 'A', #8);
    Write(Game.Runtime.Lst, #27, 'K', #194, #1);

    for K := 1 to 450 do Write(Game.Runtime.Lst, #1);
    WriteLn(Game.Runtime.Lst);
    for Y := 5 to 60 do
    begin
      Write(Game.Runtime.Lst, #27, 'K', #194, #1, #255);

      for X := 5 to 60 do
      begin
        Kind := 8;

        if Game.Campaign.Flags.Discovery[Island, X, Y] or Game.Campaign.Flags.LocalMapOwned[Island] then
          case Game.Campaign.Map[Island, X, Y] of
            0, 32..47: Kind := 1;
            12, 28: Kind := 1;
            14, 4, 48..63: Kind := 3;
            64..79: Kind := 4;
            80..95: Kind := 5;
            1..3: Kind := 2;
            18: Kind := 2;
            7: Kind := 2;
            8: Kind := 6;
            5: Kind := 9;
          else Kind := 7;
          end;

        for I := 0 to 7 do Write(Game.Runtime.Lst, Chr(PrinterColumnPatterns[Kind, I]));
      end;

      WriteLn(Game.Runtime.Lst, #255);
    end;

    Write(Game.Runtime.Lst, #27, 'K', #194, #1);
    for K := 1 to 450 do Write(Game.Runtime.Lst, #128);
    WriteLn(Game.Runtime.Lst);
  end;
end;

procedure DrawMapCursor(Color: byte);
var
  I: byte;

begin
  for I := 0 to 2 do DrawLine(X, Y + I, X + 3, Y + I, Color);
end;

begin
  RevealAll := false;
  DrawDialog(104, 24, 392, 254);

  if Game.Campaign.Flags.LocalMapOwned[Island] then HeaderPrompt(4)
  else HeaderPrompt(5);
  DrawLine(105, 38, 391, 38, 15);
  DrawLine(105, 240, 391, 240, 15);
  DrawLine(105, 37, 391, 37, 7);
  DrawLine(105, 39, 391, 39, 7);
  DrawLine(105, 239, 391, 239, 7);
  DrawLine(105, 241, 391, 241, 7);
  DrawIslandName(Island, 26, 28);
  DrawText(false, 20, 244, XCaption);
  Str(Game.Campaign.Hero.X, Game.Runtime.TextBuffer);
  DrawText(false, 23, 244, Game.Runtime.TextBuffer);
  DrawText(false, 37, 244, YCaption);
  Str(Game.Campaign.Hero.Y, Game.Runtime.TextBuffer);
  DrawText(false, 40, 244, Game.Runtime.TextBuffer);
Render:
  Phase := 255;

  for Y := 0 to 65 do
    for X := 0 to 65 do
    begin
      Phase := Phase xor 255;

      if Game.Campaign.Flags.Discovery[Island, X, Y] or RevealAll then
        case Game.Campaign.Map[Island, X, Y] of
          32..47: MapDot(Phase, X, Y, 14, CursorOffset, byte(CursorOldColor));
          48..63: MapDot(Phase, X, Y, 9, CursorOffset, byte(CursorOldColor));
          64..79: MapDot(Phase, X, Y, 2, CursorOffset, byte(CursorOldColor));
          80..95: MapDot(Phase, X, Y, 6, CursorOffset, byte(CursorOldColor));
          0: MapDot(Phase, X, Y, 10, CursorOffset, byte(CursorOldColor));
          1: MapDot(Phase, X, Y, 15, CursorOffset, byte(CursorOldColor));
          2: MapDot(Phase, X, Y, 8, CursorOffset, byte(CursorOldColor));
          3: MapDot(Phase, X, Y, 15, CursorOffset, byte(CursorOldColor));
          18: MapDot(Phase, X, Y, 7, CursorOffset, byte(CursorOldColor));
          4: MapDot(Phase, X, Y, 7, CursorOffset, byte(CursorOldColor));
          14: MapDot(Phase, X, Y, 15, CursorOffset, byte(CursorOldColor));
          5: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          7: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          8: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          9: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          10: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          11: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          22: MapDot(Phase, X, Y, 13, CursorOffset, byte(CursorOldColor));
          23: MapDot(Phase, X, Y, 1, CursorOffset, byte(CursorOldColor));
          12: MapDot(Phase, X, Y, 12, CursorOffset, byte(CursorOldColor));
          28: MapDot(Phase, X, Y, 12, CursorOffset, byte(CursorOldColor));
        end
      else MapDot(Phase, X, Y, 0, CursorOffset, byte(CursorOldColor));
    end;

  X := Game.Campaign.Hero.X * 4 + 120;
  Y := Game.Campaign.Hero.Y * 3 + 40;
  DrawText(false, 31, 42, NorthCaption);
  DrawText(false, 31, 228, SouthCaption);
  DrawText(false, 14, 140, WestCaption);
  DrawText(false, 47, 140, EastCaption);

  repeat
    repeat
    DrawMapCursor(12);
    Delay(50);
    DrawMapCursor(4);
    Delay(50);
    until BIOSKeyPressed;
    Game.Runtime.LastScan := ReadScanCode;

    if Game.Runtime.LastScan = 63 then
    begin
      PrintMap;
      goto Render
    end;

    if (Game.Runtime.LastScan = 57) and Game.Campaign.Flags.LocalMapOwned[Island] then
    begin
      RevealAll := not RevealAll;
      goto Render;
    end;
  until Game.Runtime.LastScan = 1;
  HeaderPrompt(0);
end;

end.
