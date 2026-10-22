unit KBSave;
{$G+,R-,S-,I+,A+}

interface

procedure PrepareSave;
procedure WriteCampaign;
procedure ReadCampaign;

implementation

uses KBState, KBTables, KBFiles;

procedure PrepareSave;
var
  I: byte;

begin
  Game.Map[Game.Island, Game.WizardPosition.X, Game.WizardPosition.Y] := 0;
  Game.Map[Game.Island, Game.MagePosition.X, Game.MagePosition.Y] := 0;
  Game.ArchivedIsland := Game.Island;
  Game.ArchiveMarker := 0;

  for I := 25 to 29 do Game.Mutants[I] := CreatureDefinitions[I];
end;

procedure WriteCampaign;
begin
  asm
    lea si, Game.Discovery
    lea di, Game.PictureBanks
    add di, 16
    mov ax, [di]
    mov bx, [di+2]
    mov es, bx
    mov di, ax
    push di
    mov cx, 21814
    xor bh, bh
    inc bh
    xor ah, ah

@Pack:
    lodsb
    or al, al
    je @Empty
    or ah, bh

@Empty:
    rol bh, 1
    jnc @Next
    mov al, ah
    xor ah, ah
    stosb

@Next:
    loop @Pack
    mov al, ah
    stosb
    lea si, Game.VisitedCastles
    mov cx, 12501
    rep movsw
    lea dx, Game.DataFileName
    mov bx, dx
    inc dx
    mov al, [bx]
    xor ah, ah
    add bx, ax
    inc bx
    mov al, 0
    mov [bx], al
    xor cx, cx
    mov ah, 3ch
    int 21h
    mov bx, ax
    mov cx, di
    pop di
    sub cx, di
    mov dx, di
    push ds
    mov ax, es
    mov ds, ax
    mov ah, 40h
    int 21h
    mov ah, 3eh
    int 21h
    pop ds
  end;

  LoadResourceFile(Game.PictureBanks[4], Game.IslandPictureFileName);
end;

procedure ReadCampaign;
begin
  asm
    mov ax, ds
    mov es, ax
    lea dx, Game.DataFileName
    mov bx, dx
    inc dx
    mov al, [bx]
    xor ah, ah
    add bx, ax
    inc bx
    mov al, 0
    mov [bx], al
    mov ax, 3d00h
    int 21h
    jc @Finished
    mov bx, ax
    xor cx, cx
    xor dx, dx
    mov ax, 4202h
    int 21h
    mov si, ax
    mov ax, 4200h
    int 21h
    lea di, Game.PictureBanks
    mov dx, [di]
    mov cx, [di+2]
    mov ds, cx
    mov ah, 3fh
    mov cx, si
    int 21h
    mov ah, 3eh
    int 21h
    mov si, dx
    lea di, Game.Discovery
    mov cx, 21814
    inc cx
    xor bh, bh
    inc bh
    jmp @ReadPacked

@Unpack:
    xor ah, ah
    test al, bh
    je @Store
    inc ah

@Store:
    mov es:[di], ah
    inc di
    rol bh, 1
    jnc @Continue

@ReadPacked:
    lodsb

@Continue:
    loop @Unpack
    lea di, Game.VisitedCastles
    mov cx, 12501
    rep movsw
    mov ax, es
    mov ds, ax

@Finished:
  end;
end;


end.
