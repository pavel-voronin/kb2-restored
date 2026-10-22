unit KBFiles;
{$G+,R-,S-,I+,A+}

interface

procedure LoadResourceFile(Buffer: pointer; Text: string);
procedure LoadCreatureFrames(Packet: byte; Buffer: pointer; Text: string);
procedure CopyRecord(SourceIndex, DestinationIndex: byte; Bytes: word; Source, Destination: pointer);

implementation

uses Dos;

procedure LoadResourceFile(Buffer: pointer; Text: string);
begin
  asm
    mov dx, sp
    push ds
    mov ax, ss
    mov ds, ax
    mov bx, dx
    inc dx
    mov al, byte ptr [bx]
    xor ah, ah
    add bx, ax
    inc bx
    mov al, 0
    mov byte ptr [bx], al
    mov ax, $3d00
    int $21
    mov bx, ax
    xor cx, cx
    xor dx, dx
    mov ax, $4202
    int $21
    mov si, ax
    mov ax, $4200
    int $21
    lds dx, dword ptr [bp + $a]
    mov ah, $3f
    mov cx, si
    int $21
    mov ah, $3e
    int $21
    pop ds
  end;
end;

procedure LoadCreatureFrames(Packet: byte; Buffer: pointer; Text: string);
begin
  asm
    mov dx, sp
    push ds
    mov ax, ss
    mov ds, ax
    mov bx, dx
    inc dx
    mov al, byte ptr [bx]
    xor ah, ah
    add bx, ax
    inc bx
    mov al, 0
    mov byte ptr [bx], al
    mov ax, $3d00
    int $21
    mov bx, ax
    mov al, byte ptr [bp + $e]
    xor ah, ah
    mov si, $21c0
    mul si
    mov dx, ax
    xor cx, cx
    mov ax, $4201
    int $21
    lds dx, dword ptr [bp + $a]
    mov ah, $3f
    mov cx, si
    int $21
    mov ah, $3e
    int $21
    pop ds
  end;
end;

procedure CopyRecord(SourceIndex, DestinationIndex: byte; Bytes: word; Source, Destination: pointer);
begin
  asm
    push ds
    lds si, dword ptr [bp + $a]
    les di, dword ptr [bp + 6]
    mov cx, word ptr [bp + $e]
    mov al, byte ptr [bp + $12]
    xor ah, ah
    mul cx
    add si, ax
    mov al, byte ptr [bp + $10]
    xor ah, ah
    mul cx
    add di, ax
    shr cx, 1
    rep movsw
    pop ds
  end;
end;


end.
