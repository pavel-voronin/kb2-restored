unit KBLpt;
{$G-,R-,S-,I-,A+}

interface

implementation

uses KBState;

begin
  Assign(Game.Lst, 'LPT1');
  Rewrite(Game.Lst);
  asm
    mov bx, word ptr Game.Lst
    mov ax, $4400
    int $21
    or dl, $20
    mov dh, 0
    mov ax, $4401
    int $21
  end;
end.
