unit KBLpt;
{$G-,R-,S-,I-,A+}

interface

procedure InitializePrinter;

implementation

uses KBState;

procedure InitializePrinter;
begin
  Assign(Game.Runtime.Lst, 'LPT1');
  Rewrite(Game.Runtime.Lst);
  asm
    mov bx, word ptr Game.Runtime.Lst
    mov ax, $4400
    int $21
    or dl, $20
    mov dh, 0
    mov ax, $4401
    int $21
  end;
end;

end.
