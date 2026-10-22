unit KBGfx;
{$G+,R-,S-,A+}

interface

uses KBState;

procedure SetVideoPage(Page: byte);

procedure LoadScreenPicture;

procedure DrawText(Highlighted: boolean; X: byte; Y: word; Text: string);

procedure ClearRectangle(X1, Y1, X2, Y2: word);

procedure DrawPictureTile(Destination: word; Picture: byte);

procedure DrawTile(Destination: word; Foreground, Background: byte);

procedure ComposeTile(Picture: byte);

procedure DrawMaskedTile(Destination: word; Foreground, Background: byte);

procedure MirrorTileArt(Picture: byte);

procedure AdvanceNearbyRoamers;

procedure RevealNearbyTiles;

procedure ClearPicturePlanes(Destination: word; Mask: byte);

procedure DrawPicturePlanes(Destination: word; Picture, Mask: byte);

procedure StoreMutantFrames(Packet, Picture: byte);

procedure DrawLine(X1, Y1, X2, Y2: word; Color: byte);

implementation

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
  lea bx, Game.PictureFileName
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
  mov di, word ptr Game.PicturePage
  lea si, Game.PictureBanks
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
    add di, word ptr Game.PicturePage
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
    lea si, Game.Font
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
    add di, word ptr Game.PicturePage
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
    add di, word ptr Game.PicturePage
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
    lea bx, Game.PictureBanks
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
    lea bx, Game.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    mov word ptr Game.BlitOverlayOffset, di
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.BlitOverlaySegment, ax
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
    lea bx, Game.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    mov word ptr Game.BlitSourceOffset, si
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.BlitSourceSegment, ax
    mov bx, si
    mov ax, $a000
    mov word ptr Game.BlitDestSegment, ax
    lea bp, [bp + $a]
    mov bp, word ptr [bp]
    mov word ptr Game.BlitDestOffset, bp
    lea di, Game.PictureMask
    mov bx, di
    mov si, word ptr Game.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.BlitSourceSegment
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
    mov bp, word ptr Game.BlitDestOffset
    mov bx, word ptr Game.BlitSourceOffset
    mov di, word ptr Game.BlitOverlayOffset
    lea si, Game.PictureMask
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
    mov byte ptr Game.BlitWordsLeft, 6

  @TileWord:
    lodsw
    mov es, word ptr Game.BlitSourceSegment
    mov cx, word ptr es:[bx]
    and cx, ax
    not ax
    mov es, word ptr Game.BlitOverlaySegment
    mov dx, word ptr es:[di]
    and dx, ax
    or dx, cx
    mov es, word ptr Game.BlitDestSegment
    mov word ptr es:[bp], dx
    inc bx
    inc bx
    inc di
    inc di
    inc bp
    inc bp
    dec byte ptr Game.BlitWordsLeft
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
    lea bx, Game.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    mov word ptr Game.BlitOverlayOffset, di
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.BlitOverlaySegment, ax
    les bx, dword ptr Game.PictureBanks[14*4]
    mov word ptr Game.BlitSourceOffset, bx
    mov ax, es
    mov word ptr Game.BlitSourceSegment, ax
    lea bx, Game.PictureBanks
    mov ax, word ptr [bx]
    add ax, $9d80
    mov word ptr Game.BlitDestOffset, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.BlitDestSegment, ax
    lea di, Game.PictureMask
    mov bx, di
    mov si, word ptr Game.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.BlitSourceSegment
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
    mov di, word ptr Game.BlitDestOffset
    mov bx, word ptr Game.BlitSourceOffset
    mov bp, word ptr Game.BlitOverlayOffset
    lea si, Game.PictureMask
    mov ah, 4

  @ComposePlane:
    push si
    mov al, $3c

  @ComposeScanline:
    push ax
    mov byte ptr Game.BlitWordsLeft, 6

  @ComposeWord:
    lodsw
    mov es, word ptr Game.BlitSourceSegment
    mov cx, word ptr es:[bx]
    and cx, ax
    not ax
    mov es, word ptr Game.BlitOverlaySegment
    mov dx, word ptr es:[bp]
    and ax, dx
    or ax, cx
    mov es, word ptr Game.BlitDestSegment
    stosw
    inc bx
    inc bx
    inc bp
    inc bp
    dec byte ptr Game.BlitWordsLeft
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
    lea bx, Game.PictureBanks
    add bx, cx
    mov si, word ptr [bx]
    add si, ax
    mov word ptr Game.BlitSourceOffset, si
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov word ptr Game.BlitSourceSegment, ax
    lea bx, [bp + $a]
    mov ax, word ptr ss:[bx]
    mov word ptr Game.BlitDestOffset, ax
    lea di, Game.PictureMask
    mov bx, di
    mov si, word ptr Game.BlitSourceOffset
    mov ax, ds
    mov es, ax
    mov cx, $168
    xor ax, ax
    rep stosw
    mov di, bx
    mov ds, word ptr Game.BlitSourceSegment
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
    mov di, word ptr Game.BlitDestOffset
    lea si, Game.PictureMask
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
    lea bx, Game.PictureBanks
    add bx, cx
    mov di, word ptr [bx]
    add di, ax
    inc bx
    inc bx
    mov ax, word ptr [bx]
    mov es, ax
    lea si, Game.PictureMask
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

procedure LocateViewportBuffer; assembler;
asm
  mov ax, ds
  mov es, ax
  mov al, byte ptr Game.Island
  dec al
  xor ah, ah
  mov dx, $1104
  mul dx
  add di, ax
  mov word ptr Game.IslandBufferOffset, di
  lea bx, Game.Hero
  mov al, byte ptr [bx]
  dec al
  dec al
  mov byte ptr Game.ViewportLeftX, al
  mov cl, $42
  mul cl
  add di, ax
  inc bx
  mov al, byte ptr [bx]
  dec al
  dec al
  mov byte ptr Game.ViewportTopY, al
  xor ah, ah
  add di, ax
  mov word ptr Game.ViewportBufferOffset, di
end;

procedure AdvanceNearbyRoamers; assembler;
asm
  push bp
  xor al, al
  cmp byte ptr Game.WorldMapRedraw, al
  je @BeginRoamerScan
  dec byte ptr Game.WorldMapRedraw

@BeginRoamerScan:
  inc al
  mov byte ptr Game.WorldMapPending, al
  lea di, Game.Map
  call LocateViewportBuffer
  mov al, 5
  mov cl, 5
  mov ch, $1c

@RoamerColumn:
  mov ah, 5

@RoamerCell:
  cmp byte ptr [di], cl
  je @CheckEnemyGrace
  cmp byte ptr [di], ch
  je @ChooseRoamerDestination
  inc di
  dec ah
  jne @RoamerCell

@NextRoamerColumn:
  add di, $3d
  dec al
  jne @RoamerColumn
  jmp @FinalizeRoamerMarkers

@CheckEnemyGrace:
  cmp byte ptr Game.EnemyGrace, 0
  je @ChooseRoamerDestination
  dec byte ptr Game.EnemyGrace
  inc di
  dec ah
  or ah, ah
  jne @RoamerCell
  jmp @NextRoamerColumn

@ChooseRoamerDestination:
  inc di
  mov si, $505
  mov bp, ax
  sub si, ax
  mov ax, si
  mov byte ptr Game.StepX, al
  mov byte ptr Game.StepY, ah
  mov dx, ax
  xor bx, bx
  inc bl
  inc bl
  inc bh
  add dl, byte ptr Game.ViewportLeftX
  add dh, byte ptr Game.ViewportTopY
  sub dl, byte ptr Game.GenerationX
  jge @AbsoluteHeroDistanceX
  neg dl

@AbsoluteHeroDistanceX:
  cmp dl, bh
  ja @ChooseWindowStep
  sub dh, byte ptr Game.GenerationY
  jge @AbsoluteHeroDistanceY
  neg dh

@AbsoluteHeroDistanceY:
  cmp dh, bh
  ja @ChooseWindowStep
  mov bx, word ptr Game.IslandBufferOffset
  mov al, byte ptr Game.GenerationX
  mov ah, $42
  mul ah
  add bx, ax
  mov al, byte ptr Game.GenerationY
  xor ah, ah
  add bx, ax
  jmp @TestRoamerDestination

@ChooseWindowStep:
  cmp al, bl
  jb @StepEastSide
  je @StepVertical
  cmp ah, bl
  jb @StepSouthWest
  ja @StepNorthWest
  mov dx, $ffbd
  jmp @OffsetDestination

@StepSouthWest:
  mov dx, $ffbe
  jmp @OffsetDestination

@StepNorthWest:
  mov dx, $ffbc
  jmp @OffsetDestination

@StepEastSide:
  cmp ah, bl
  jb @StepSouthEast
  ja @StepNorthEast
  mov dx, $41
  jmp @OffsetDestination

@StepSouthEast:
  mov dx, $42
  jmp @OffsetDestination

@StepNorthEast:
  mov dx, $40
  jmp @OffsetDestination

@StepVertical:
  cmp ah, bl
  jb @StepSouth
  mov dx, $fffe
  jmp @OffsetDestination

@StepSouth:
  xor dx, dx

@OffsetDestination:
  mov bx, di
  add bx, dx

@TestRoamerDestination:
  cmp byte ptr [bx], 0
  je @MarkRoamerDestination
  cmp byte ptr [bx], 9
  je @MarkRoamerDestination
  cmp byte ptr [bx], $a
  je @MarkRoamerDestination
  mov ax, bp
  dec ah
  or ah, ah
  jne @ContinueRoamerScan
  jmp @NextRoamerColumn

@ContinueRoamerScan:
  jmp @RoamerCell

@MarkRoamerDestination:
  mov ax, bx
  sub ax, word ptr Game.IslandBufferOffset
  mov dl, $42
  div dl
  mov byte ptr Game.RoamerNextX, al
  mov byte ptr Game.RoamerNextY, ah
  mov si, di
  dec si
  cmp byte ptr [si], 5
  je @MarkArmyDestination
  mov byte ptr Game.WorldMapPending, 0
  mov byte ptr [bx], $fe
  mov byte ptr [si], 0
  lea bx, Game.MagePosition
  inc bx
  jmp @UpdateRoamerPosition

@MarkArmyDestination:
  mov byte ptr [bx], $ff
  mov byte ptr [si], 0
  mov al, byte ptr Game.Island
  dec al
  xor ah, ah
  mov dx, $165
  mul dx
  lea bx, Game.WanderingArmies
  add bx, ax
  mov dx, $11
  mov al, byte ptr Game.ViewportLeftX
  add al, byte ptr Game.StepX
  mov ah, byte ptr Game.ViewportTopY
  add ah, byte ptr Game.StepY

@FindArmyX:
  cmp byte ptr [bx], al
  je @FindArmyY
  add bx, dx
  jmp @FindArmyX

@FindArmyY:
  inc bx
  cmp byte ptr [bx], ah
  je @UpdateRoamerPosition
  add bx, dx
  dec bx
  jmp @FindArmyX

@UpdateRoamerPosition:
  mov ax, bp
  dec ah
  dec bx
  mov dl, byte ptr Game.RoamerNextX
  mov dh, byte ptr Game.RoamerNextY
  mov word ptr [bx], dx
  or ah, ah
  jne @ContinueMovedRoamerScan
  jmp @NextRoamerColumn

@ContinueMovedRoamerScan:
  jmp @RoamerCell

@FinalizeRoamerMarkers:
  mov bx, word ptr Game.ViewportBufferOffset
  mov al, 5
  mov cl, $ff
  mov ch, $fe

@MarkerColumn:
  mov ah, 5

@MarkerCell:
  cmp byte ptr [bx], cl
  je @RestoreArmyMarker
  cmp byte ptr [bx], ch
  je @RestoreMageMarker

@NextMarkerCell:
  inc bx
  dec ah
  jne @MarkerCell
  add bx, $3d
  dec al
  jne @MarkerColumn
  jmp @WorldMapDone

@RestoreArmyMarker:
  mov byte ptr [bx], 5
  jmp @NextMarkerCell

@RestoreMageMarker:
  mov byte ptr [bx], $1c
  jmp @NextMarkerCell

@WorldMapDone:
  pop bp
end;

procedure RevealNearbyTiles; assembler;
asm
  lea di, Game.Discovery
  call LocateViewportBuffer
  xor al, al
  inc al
  mov ah, 5

@RevealColumn:
  mov cx, 5
  rep stosb
  add di, $3d
  dec ah
  jne @RevealColumn
end;

procedure ClearPicturePlanes(Destination: word; Mask: byte);
begin
  asm
    mov ax, $a000
    mov es, ax
    lea bx, [bp + 8]
    mov di, word ptr ss:[bx]
    add di, word ptr Game.PicturePage
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
    add di, word ptr Game.PicturePage
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
    lea bx, Game.PictureBanks
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
    les di, dword ptr Game.PictureBanks[10*4]
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
    lea dx, Game.ReservePictureFileName
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
    add bx, word ptr Game.PicturePage
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
