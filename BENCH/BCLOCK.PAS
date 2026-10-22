unit BClock;
{$G+,R-,S-,A+}
interface
procedure StartClock;
procedure StopClock;
function ClockTicks: longint;
implementation
{ Делитель PIT сохраняет обычную частоту IRQ0; режим 2 даёт линейный отсчёт. }
procedure StartClock;
begin
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;
end;
procedure StopClock;
begin
  Port[$43] := $36;
  Port[$40] := 0;
  Port[$40] := 0;
end;
function ClockTicks: longint; assembler;
asm
  pushf
  cli
  push bx
  push es
  mov ax, $40
  mov es, ax
  mov dx, es:[$6c]
  xor al, al
  out $43, al
  in al, $40
  mov bl, al
  in al, $40
  mov bh, al
  { IRQ0 мог поступить до защёлкивания, но BIOS ещё не обновил счётчик. }
  mov al, $0a
  out $20, al
  in al, $20
  test al, 1
  jz @Ready
  test bh, $80
  jz @Ready
  inc dx
@Ready:
  mov ax, bx
  neg ax
  pop es
  pop bx
  popf
end;
end.
