unit KBGfx;
{$G+,R-,S-,A+}

interface

procedure SetVideoPage(Page: byte);

procedure LoadScreenPicture;

procedure DrawText(Highlighted: boolean; X: byte; Y: word; Text: string);

procedure ClearRectangle(X1, Y1, X2, Y2: word);

procedure DrawPictureTile(Destination: word; Picture: byte);

procedure DrawTile(Destination: word; Foreground, Background: byte);

procedure ComposeTile(Picture: byte);

procedure DrawMaskedTile(Destination: word; Foreground, Background: byte);

procedure MirrorTileArt(Picture: byte);

procedure ClearPicturePlanes(Destination: word; Mask: byte);

procedure DrawPicturePlanes(Destination: word; Picture, Mask: byte);

procedure StoreMutantFrames(Packet, Picture: byte);

procedure DrawLine(X1, Y1, X2, Y2: word; Color: byte);

implementation

uses KBState;

procedure SetVideoPage(Page: byte);
begin
  asm
    mov al, byte ptr [bp + 6]
    mov ah, 5
    int $10
  end;
end;

{ Перед каждой плоскостью записана её длина. }
procedure LoadScreenPicture; assembler;
asm
  push bp
  push ds
  mov ax, $a000
  mov es, ax
  xor cx, cx
  lea bx, Game.Runtime.PictureFileName
  mov dx, bx
  mov al, byte ptr [bx]
  xor ah, ah
  add bx, ax
  inc bx
  mov al, 0
  mov byte ptr [bx], al
  inc dx
  mov ax, $3d00
  int $21
  mov bx, ax
  mov di, word ptr Game.Runtime.PicturePage
  lea si, Game.Runtime.PictureBanks
  add si, $10
  mov dx, word ptr [si]
  mov ax, word ptr [si + 2]
  mov ds, ax
  mov si, dx
  mov ax, $802

@ScreenPlane:
  push di
  push si
  mov bp, ax
  mov dx, si
  mov cx, 2
  mov ah, $3f
  int $21
  mov cx, word ptr [si]
  xor bh, bh
  mov ah, $3f
  int $21
  mov dx, $3c4
  mov ax, bp
  out dx, ax
  { Плоскость без сжатия занимает 28000 байт. }
  cmp cx, $6d60
  jb @DecodeScreenByte
  shr cx, 1
  rep movsw
  jmp @ScreenPlaneDone

@DecodeScreenByte:
  lodsb
  cmp al, bh
  je @ExpandScreenRun
  not bh
  cmp al, bh
  je @ExpandScreenRun
  stosb
  loop @DecodeScreenByte
  jmp @ScreenPlaneDone

{ После 0 и 255 записано число повторов - слово. }
@ExpandScreenRun:
  dec cx
  push cx
  mov cx, word ptr [si]
  inc si
  inc si
  rep stosb
  pop cx
  dec cx
  dec cx
  jne @DecodeScreenByte

@ScreenPlaneDone:
  mov ax, bp
  pop si
  pop di
  shr ah, 1
  jne @ScreenPlane
  mov ah, $3e
  int $21
  pop ds
  pop bp
end;

{ В строке экрана 80 байт, в знаке 8 строк. }
procedure DrawText(Highlighted: boolean; X: byte; Y: word; Text: string);
begin
  asm
    mov bx, sp
    mov ax, $a000
    mov es, ax
    mov dx, word ptr [bp + $a]
    mov ax, $50
    mul dx
    mov dl, byte ptr [bp + $c]
    xor dh, dh
    mov di, dx
    add di, ax
    add di, word ptr Game.Runtime.PicturePage
    mov cl, byte ptr ss:[bx]
    xor ch, ch
    mov dx, $3c4
    mov ax, $f02
    out dx, ax

  @DrawGlyph:
    inc bx
    mov al, byte ptr ss:[bx]
    xor ah, ah
    shl ax, 1
    shl ax, 1
    shl ax, 1
    lea si, Game.Runtime.Font
    add si, ax
    movsb
    push di
    add di, $4f
    movsb
    add di, $4f
    movsb
    add di, $4f
    movsb
    add di, $4f
    movsb
    add di, $4f
    movsb
    add di, $4f
    movsb
    add di, $4f
    movsb
    pop di
    cmp byte ptr [bp + $e], 0
    je @GlyphDone
    push di
    dec di
    mov ax, $402
    out dx, ax
    mov al, $ff
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    add di, $4f
    stosb
    pop di
    mov ax, $f02
    out dx, ax

  @GlyphDone:
    loop @DrawGlyph
  end;
end;

procedure ClearRectangle(X1, Y1, X2, Y2: word);
begin
  asm
    mov ax, $a000
    mov es, ax
    mov cl, 4
    mov si, word ptr [bp + 8]
    sub si, word ptr [bp + $c]
    shr si, cl
    mov ax, word ptr [bp + $a]
    mov dx, $50
    mul dx
    mov di, word ptr [bp + $c]
    dec cl
    shr di, cl
    add di, ax
    add di, word ptr Game.Runtime.PicturePage
    mov bx, word ptr [bp + 6]
    sub bx, word ptr [bp + $a]
    inc bx
    mov ax, $f02
    mov dx, $3c4
    out dx, ax
    mov dx, $50
    xor ax, ax

  @ClearScanline:
    push di
    mov cx, si
    rep stosw
    pop di
    add di, dx
    dec bx
    jne @ClearScanline
  end;
end;

procedure DrawPictureTile(Destination: word; Picture: byte);
begin
  asm
    push ds
    mov ax, $a000
    mov es, ax
    lea bx, [bp + 8]
    mov di, word ptr ss:[bx]
    add di, word ptr Game.Runtime.PicturePage
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 6]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov ds, ax
    mov ax, $802
    mov bh, 6
    xor ch, ch

  @PortraitPlane:
    push di
    mov dx, $3c4
    out dx, ax
    mov bl, $3c
    mov dx, $44

  @PortraitScanline:
    mov cl, bh
    rep movsw
    add di, dx
    dec bl
    jne @PortraitScanline
    pop di
    shr ah, 1
    jae @PortraitPlane
    pop ds
  end;
end;

procedure DrawTile(Destination: word; Foreground, Background: byte);
begin
  asm
    push bp
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 8]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    mov word ptr Game.Runtime.BlitOverlayOffset, di
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.Runtime.BlitOverlaySegment, ax
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 6]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    mov word ptr Game.Runtime.BlitSourceOffset, si
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.Runtime.BlitSourceSegment, ax
    mov bx, si
    mov ax, $a000
    mov word ptr Game.Runtime.BlitDestSegment, ax
    lea bp, [bp + $a]
    mov bp, word ptr [bp]
    mov word ptr Game.Runtime.BlitDestOffset, bp
    lea di, Game.Runtime.PictureMask
    mov bx, di
    mov si, word ptr Game.Runtime.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.Runtime.BlitSourceSegment
    mov bl, 4
    mov bp, 0
    mov dx, $ffff

  @TileMaskPlane:
    push di
    not bp
    mov cx, $168
    cmp bp, dx
    je @TileInvertedMaskWord
    jmp @TileMaskWord

  @TileInvertedMaskWord:
    lodsw
    xor ax, dx
    or word ptr es:[di], ax
    inc di
    inc di
    loop @TileInvertedMaskWord
    jmp @TileMaskPlaneDone

  @TileMaskWord:
    lodsw
    or word ptr es:[di], ax
    inc di
    inc di
    loop @TileMaskWord

  @TileMaskPlaneDone:
    pop di
    dec bl
    jne @TileMaskPlane
    mov ax, es
    mov ds, ax
    mov bp, word ptr Game.Runtime.BlitDestOffset
    mov bx, word ptr Game.Runtime.BlitSourceOffset
    mov di, word ptr Game.Runtime.BlitOverlayOffset
    lea si, Game.Runtime.PictureMask
    mov ah, 8

  @TilePlane:
    push bp
    push si
    mov dx, $3c4
    mov al, 2
    out dx, ax
    mov al, $3c

  @TileScanline:
    push ax
    mov byte ptr Game.Runtime.BlitWordsLeft, 6

  @TileWord:
    lodsw
    mov es, word ptr Game.Runtime.BlitSourceSegment
    mov cx, word ptr es:[bx]
    and cx, ax
    not ax
    mov es, word ptr Game.Runtime.BlitOverlaySegment
    mov dx, word ptr es:[di]
    and dx, ax
    or dx, cx
    mov es, word ptr Game.Runtime.BlitDestSegment
    mov word ptr es:[bp], dx
    inc bx
    inc bx
    inc di
    inc di
    inc bp
    inc bp
    dec byte ptr Game.Runtime.BlitWordsLeft
    jne @TileWord
    add bp, $44
    pop ax
    dec al
    jne @TileScanline
    pop si
    pop bp
    shr ah, 1
    jne @TilePlane
    pop bp
  end;
end;

procedure ComposeTile(Picture: byte);
begin
  asm
    push bp
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 6]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    mov word ptr Game.Runtime.BlitOverlayOffset, di
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.Runtime.BlitOverlaySegment, ax
    les bx, dword ptr Game.Runtime.PictureBanks[14*4]
    mov word ptr Game.Runtime.BlitSourceOffset, bx
    mov ax, es
    mov word ptr Game.Runtime.BlitSourceSegment, ax
    lea bx, Game.Runtime.PictureBanks
    mov ax, word ptr [bx]
    add ax, $9d80
    mov word ptr Game.Runtime.BlitDestOffset, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.Runtime.BlitDestSegment, ax
    lea di, Game.Runtime.PictureMask
    mov bx, di
    mov si, word ptr Game.Runtime.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.Runtime.BlitSourceSegment
    mov bl, 4
    mov bp, 0
    mov dx, $ffff

  @ComposeMaskPlane:
    push di
    not bp
    mov cx, $168
    cmp bp, dx
    je @ComposeInvertedMaskWord
    jmp @ComposeMaskWord

  @ComposeInvertedMaskWord:
    lodsw
    xor ax, dx
    or word ptr es:[di], ax
    inc di
    inc di
    loop @ComposeInvertedMaskWord
    jmp @ComposeMaskPlaneDone

  @ComposeMaskWord:
    lodsw
    or word ptr es:[di], ax
    inc di
    inc di
    loop @ComposeMaskWord

  @ComposeMaskPlaneDone:
    pop di
    dec bl
    jne @ComposeMaskPlane
    mov ax, es
    mov ds, ax
    mov di, word ptr Game.Runtime.BlitDestOffset
    mov bx, word ptr Game.Runtime.BlitSourceOffset
    mov bp, word ptr Game.Runtime.BlitOverlayOffset
    lea si, Game.Runtime.PictureMask
    mov ah, 4

  @ComposePlane:
    push si
    mov al, $3c

  @ComposeScanline:
    push ax
    mov byte ptr Game.Runtime.BlitWordsLeft, 6

  @ComposeWord:
    lodsw
    mov es, word ptr Game.Runtime.BlitSourceSegment
    mov cx, word ptr es:[bx]
    and cx, ax
    not ax
    mov es, word ptr Game.Runtime.BlitOverlaySegment
    mov dx, word ptr es:[bp]
    and ax, dx
    or ax, cx
    mov es, word ptr Game.Runtime.BlitDestSegment
    stosw
    inc bx
    inc bx
    inc bp
    inc bp
    dec byte ptr Game.Runtime.BlitWordsLeft
    jne @ComposeWord
    pop ax
    dec al
    jne @ComposeScanline
    pop si
    dec ah
    jne @ComposePlane
    pop bp
  end;
end;

procedure DrawMaskedTile(Destination: word; Foreground, Background: byte);
begin
  asm
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 8]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    mov word ptr Game.Runtime.BlitSourceOffset, si
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.Runtime.BlitSourceSegment, ax
    lea bx, [bp + $a]
    mov ax, word ptr ss:[bx]
    mov word ptr Game.Runtime.BlitDestOffset, ax
    lea di, Game.Runtime.PictureMask
    mov bx, di
    mov si, word ptr Game.Runtime.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.Runtime.BlitSourceSegment
    mov bl, 4
    mov dx, 0

  @LandscapeMaskPlane:
    push di
    not dx
    mov cx, $168
    cmp dx, $ffff
    je @LandscapeInvertedMaskWord
    jmp @LandscapeMaskWord

  @LandscapeInvertedMaskWord:
    lodsw
    xor ax, dx
    or word ptr es:[di], ax
    inc di
    inc di
    loop @LandscapeInvertedMaskWord
    jmp @LandscapeMaskPlaneDone

  @LandscapeMaskWord:
    lodsw
    or word ptr es:[di], ax
    inc di
    inc di
    loop @LandscapeMaskWord

  @LandscapeMaskPlaneDone:
    pop di
    dec bl
    jne @LandscapeMaskPlane
    lea bx, [bp + 6]
    mov bh, byte ptr ss:[bx]
    mov dx, $3c4
    mov ah, bh
    mov al, 2
    out dx, ax
    cmp ah, 8
    jne @TestPlaneFour
    mov ax, $304
    jmp @SelectReadPlane

  @TestPlaneFour:
    cmp ah, 4
    jne @TestPlaneTwo
    mov ax, $204
    jmp @SelectReadPlane

  @TestPlaneTwo:
    cmp ah, 2
    jne @ReadPlaneZero
    mov ax, $104
    jmp @SelectReadPlane

  @ReadPlaneZero:
    mov ax, 4

  @SelectReadPlane:
    mov dx, $3ce
    out dx, ax
    mov ax, es
    mov ds, ax
    mov ax, $a000
    mov es, ax
    mov di, word ptr Game.Runtime.BlitDestOffset
    lea si, Game.Runtime.PictureMask
    mov bl, $3c

  @LandscapeScanline:
    mov cx, 6

  @LandscapeWord:
    lodsw
    mov dx, word ptr es:[di]
    or ax, dx
    stosw
    loop @LandscapeWord
    add di, $44
    dec bl
    jne @LandscapeScanline
  end;
end;

procedure MirrorTileArt(Picture: byte);
begin
  asm
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 6]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov es, ax
    lea si, Game.Runtime.PictureMask
    mov dh, 4
    mov bx, $c
    mov ah, $80

  @MirrorPlane:
    push si
    push si
    push di
    add si, $b
    mov dl, $3c

  @MirrorScanline:
    mov ch, bl

  @MirrorByte:
    xor cl, cl
    mov al, byte ptr es:[di]

  @MirrorBit:
    ror al, 1
    jae @NextMirrorBit
    or cl, ah

  @NextMirrorBit:
    ror ah, 1
    jae @MirrorBit
    mov byte ptr [si], cl
    inc di
    dec si
    dec ch
    jne @MirrorByte
    shl bl, 1
    add si, bx
    shr bl, 1
    dec dl
    jne @MirrorScanline
    pop di
    pop si
    mov cx, $168
    rep movsw
    pop si
    dec dh
    jne @MirrorPlane
  end;
end;

procedure ClearPicturePlanes(Destination: word; Mask: byte);
begin
  asm
    mov ax, $a000
    mov es, ax
    lea bx, [bp + 8]
    mov di, word ptr ss:[bx]
    add di, word ptr Game.Runtime.PicturePage
    lea bx, [bp + 6]
    mov bh, byte ptr ss:[bx]
    mov ax, $802

  @BackgroundPlane:
    test ah, bh
    je @NextBackgroundPlane
    push ax
    push di
    mov dx, $3c4
    out dx, ax
    mov bl, $3c
    mov dx, $44
    xor ax, ax

  @BackgroundScanline:
    mov cx, 6
    rep stosw
    add di, dx
    dec bl
    jne @BackgroundScanline
    pop di
    pop ax

  @NextBackgroundPlane:
    shr ah, 1
    jae @BackgroundPlane
  end;
end;

procedure DrawPicturePlanes(Destination: word; Picture, Mask: byte);
begin
  asm
    push ds
    mov ax, $a000
    mov es, ax
    lea bx, [bp + $a]
    mov di, word ptr ss:[bx]
    add di, word ptr Game.Runtime.PicturePage
    mov ax, $b40
    mov cl, 4
    lea bx, [bp + 8]
    mov ch, byte ptr ss:[bx]
    mov bl, ch
    shr ch, cl
    and bl, $f
    xor bh, bh
    mul bx
    mov cl, ch
    shl cl, 1
    shl cl, 1
    xor ch, ch
    lea bx, Game.Runtime.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov ds, ax
    lea bx, [bp + 6]
    mov bh, byte ptr ss:[bx]
    mov ax, $802

  @OverlayPlane:
    test ah, bh
    jne @CopyOverlayPlane
    add si, $2d0
    jmp @NextOverlayPlane

  @CopyOverlayPlane:
    push ax
    push di
    mov dx, $3c4
    out dx, ax
    mov ax, 6
    mov bl, $3c
    mov dx, $44

  @OverlayScanline:
    mov cx, ax
    rep movsw
    add di, dx
    dec bl
    jne @OverlayScanline
    pop di
    pop ax

  @NextOverlayPlane:
    shr ah, 1
    jae @OverlayPlane
    pop ds
  end;
end;

procedure StoreMutantFrames(Packet, Picture: byte);
begin
  asm
    push ds
    les di, dword ptr Game.Runtime.PictureBanks[10*4]
    mov al, byte ptr [bp + 6]
    xor ah, ah
    mov dx, $b40
    mul dx
    add di, ax
    push di
    add di, $870
    push es
    mov cx, $168
    xor ax, ax
    rep stosw
    lea dx, Game.Runtime.ReservePictureFileName
    mov bx, dx
    inc dx
    mov al, byte ptr [bx]
    xor ah, ah
    add bx, ax
    inc bx
    mov al, 0
    mov byte ptr [bx], al
    mov ax, $3d01
    int $21
    mov bx, ax
    mov al, byte ptr [bp + 8]
    xor ah, ah
    mov si, $21c0
    mul si
    mov dx, ax
    xor cx, cx
    mov ax, $4201
    int $21
    pop ds
    pop dx
    mov ah, $40
    mov cx, si
    int $21
    mov ah, $3e
    int $21
    pop ds
  end;
end;

procedure DrawLine(X1, Y1, X2, Y2: word; Color: byte);
begin
  asm
    push ds
    mov ax, $a000
    mov es, ax
    mov dx, $3c4
    mov ax, $f02
    out dx, ax
    mov dx, $3ce
    mov si, $50
    mov ax, word ptr [bp + $c]
    cmp ax, word ptr [bp + 8]
    jbe @OrderedLineY
    xchg word ptr [bp + 8], ax
    mov word ptr [bp + $c], ax

  @OrderedLineY:
    mov ax, word ptr [bp + $e]
    cmp ax, word ptr [bp + $a]
    jbe @OrderedLineX
    xchg word ptr [bp + $a], ax
    mov word ptr [bp + $e], ax

  @OrderedLineX:
    xor al, al
    mov ah, byte ptr [bp + 6]
    out dx, ax
    mov ax, $f01
    out dx, ax
    mov ax, word ptr [bp + $c]
    mov bx, word ptr [bp + $e]
    mov cl, bl
    mul si
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, word ptr Game.Runtime.PicturePage
    add bx, ax
    and cl, 7
    xor cl, 7
    mov ah, 1
    mov di, es
    mov ds, di
    mov dx, word ptr [bp + $e]
    cmp dx, word ptr [bp + $a]
    je @VerticalLine
    mov dx, word ptr [bp + $c]
    cmp dx, word ptr [bp + 8]
    je @HorizontalLine
    jmp @RestoreGraphicsRegisters

  @VerticalLine:
    mov di, word ptr [bp + $c]
    mov dx, word ptr [bp + 8]
    sub dx, di
    inc dx
    push dx
    shl ah, cl
    mov al, 8
    mov dx, $3ce
    out dx, ax
    pop cx

  @VerticalPixel:
    or byte ptr [bx], al
    add bx, si
    loop @VerticalPixel
    jmp @RestoreGraphicsRegisters

  @HorizontalLine:
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp + $a]
    and cl, 7
    xor cl, 7
    mov dl, $ff
    shl dl, cl
    mov ax, word ptr [bp + $a]
    mov bx, word ptr [bp + $e]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, $3ce
    mov al, 8
    mov si, di
    or bh, bh
    js @FullHorizontalBytes
    or cx, cx
    jne @FirstHorizontalByte
    and bl, bh
    jmp @LastHorizontalByte

  @FirstHorizontalByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx

  @FullHorizontalBytes:
    mov ah, $ff
    out dx, ax
    rep movsb

  @LastHorizontalByte:
    mov ah, bl
    and ah, $ff
    out dx, ax
    movsb

  @RestoreGraphicsRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov ax, $ff08
    out dx, ax
    pop ds
  end;
end;

begin
end.
