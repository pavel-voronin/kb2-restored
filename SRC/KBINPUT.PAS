unit KBInput;
{$G+,R-,S-,I+,A+}

interface

function ReadScanCode: byte;
function BIOSKeyPressed: boolean;

implementation

uses Dos;

function ReadScanCode: byte; assembler;
asm
  xor ah, ah
  int $16
  mov al, ah
end;

function BIOSKeyPressed: boolean; assembler;
asm
  xor ah, ah
  mov bl, ah
  inc ah
  int $16
  mov al, bl
  je @KeyResult
  inc al

@KeyResult:
end;

end.
