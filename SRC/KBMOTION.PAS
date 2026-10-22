unit KBMotion;
{ Движение армий рядом с героем и открытие карты. }
{$G+,R-,S-,I+,A+}

interface

procedure AdvanceNearbyRoamers;
procedure RevealNearbyTiles;

implementation

uses KBState;

procedure LocateViewportBuffer; assembler;
asm
  mov ax, ds
  mov es, ax
  mov al, byte ptr Game.Campaign.Island
  dec al
  xor ah, ah
  mov dx, $1104
  mul dx
  add di, ax
  mov word ptr Game.Runtime.IslandBufferOffset, di
  lea bx, Game.Campaign.Hero
  mov al, byte ptr [bx]
  dec al
  dec al
  mov byte ptr Game.Runtime.ViewportLeftX, al
  mov cl, $42
  mul cl
  add di, ax
  inc bx
  mov al, byte ptr [bx]
  dec al
  dec al
  mov byte ptr Game.Runtime.ViewportTopY, al
  xor ah, ah
  add di, ax
  mov word ptr Game.Runtime.ViewportBufferOffset, di
end;

procedure AdvanceNearbyRoamers; assembler;
asm
  push bp
  xor al, al
  cmp byte ptr Game.Runtime.WorldMapRedraw, al
  je @BeginRoamerScan
  dec byte ptr Game.Runtime.WorldMapRedraw

@BeginRoamerScan:
  inc al
  mov byte ptr Game.Runtime.WorldMapPending, al
  lea di, Game.Campaign.Map
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
  cmp byte ptr Game.Campaign.EnemyGrace, 0
  je @ChooseRoamerDestination
  dec byte ptr Game.Campaign.EnemyGrace
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
  mov byte ptr Game.Runtime.StepX, al
  mov byte ptr Game.Runtime.StepY, ah
  mov dx, ax
  xor bx, bx
  inc bl
  inc bl
  inc bh
  add dl, byte ptr Game.Runtime.ViewportLeftX
  add dh, byte ptr Game.Runtime.ViewportTopY
  sub dl, byte ptr Game.World.GenerationX
  jge @AbsoluteHeroDistanceX
  neg dl

@AbsoluteHeroDistanceX:
  cmp dl, bh
  ja @ChooseWindowStep
  sub dh, byte ptr Game.World.GenerationY
  jge @AbsoluteHeroDistanceY
  neg dh

@AbsoluteHeroDistanceY:
  cmp dh, bh
  ja @ChooseWindowStep
  mov bx, word ptr Game.Runtime.IslandBufferOffset
  mov al, byte ptr Game.World.GenerationX
  mov ah, $42
  mul ah
  add bx, ax
  mov al, byte ptr Game.World.GenerationY
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
  sub ax, word ptr Game.Runtime.IslandBufferOffset
  mov dl, $42
  div dl
  mov byte ptr Game.Runtime.RoamerNextX, al
  mov byte ptr Game.Runtime.RoamerNextY, ah
  mov si, di
  dec si
  cmp byte ptr [si], 5
  je @MarkArmyDestination
  mov byte ptr Game.Runtime.WorldMapPending, 0
  mov byte ptr [bx], $fe
  mov byte ptr [si], 0
  lea bx, Game.World.MagePosition
  inc bx
  jmp @UpdateRoamerPosition

@MarkArmyDestination:
  mov byte ptr [bx], $ff
  mov byte ptr [si], 0
  mov al, byte ptr Game.Campaign.Island
  dec al
  xor ah, ah
  mov dx, $165
  mul dx
  lea bx, Game.Campaign.WanderingArmies
  add bx, ax
  mov dx, $11
  mov al, byte ptr Game.Runtime.ViewportLeftX
  add al, byte ptr Game.Runtime.StepX
  mov ah, byte ptr Game.Runtime.ViewportTopY
  add ah, byte ptr Game.Runtime.StepY

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
  mov dl, byte ptr Game.Runtime.RoamerNextX
  mov dh, byte ptr Game.Runtime.RoamerNextY
  mov word ptr [bx], dx
  or ah, ah
  jne @ContinueMovedRoamerScan
  jmp @NextRoamerColumn

@ContinueMovedRoamerScan:
  jmp @RoamerCell

@FinalizeRoamerMarkers:
  mov bx, word ptr Game.Runtime.ViewportBufferOffset
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
  lea di, Game.Campaign.Flags.Discovery
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


end.
