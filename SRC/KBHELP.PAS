unit KBHelp;
{$G+,R-,S-,I+,A+}

interface

procedure AdventureHelp;
procedure Credits;

implementation

uses KBAdvent, KBTables, KBUI, KBGfx, KBInput, Crt, KBState;

procedure AdventureHelp;
begin
  DrawDialog(8, 230, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 2, 240, '( A ) обход своей аpмии');
  DrawText(false, 2, 248, '( B ) пpосмотpеть товаp');
  DrawText(false, 2, 256, '( C ) поиск заклинания');
  DrawText(false, 2, 264, '( D ) отпустить воинов');
  DrawText(false, 2, 272, '( E ) закончить неделю');
  Game.Runtime.TextBuffer := '( F ) ' + SoundToggleCaptions[shortint(Game.Runtime.SoundDisabled)] + ' звук';
  DrawText(false, 2, 280, Game.Runtime.TextBuffer);
  DrawText(false, 2, 288, '( G ) "Автоpа!"');
  DrawText(false, 2, 296, '( I ) вспомнить договоp');
  DrawText(false, 2, 304, '( M ) каpта местности');
  DrawText(false, 30, 240, '( N ) дpугой континент');
  DrawText(false, 30, 248, '( P ) pекламная пауза');
  DrawText(false, 30, 256, '( S ) запись игpы');
  DrawText(false, 30, 264, '( T ) вызвать смеpч');
  DrawText(false, 30, 272, '( U ) волшебство');
  DrawText(false, 30, 280, '( V ) текущий статус');
  DrawText(false, 30, 288, '( W ) вызов pаботников');

  if CountRitualSpells > 0 then DrawText(false, 30, 296, '( R ) пpосмотpеть заклинания');
  Game.Runtime.LastScan := Ord(ReadKey);
  HeaderPrompt(0);
end;

procedure Credits;
begin
  DrawDialog(8, 210, 488, 320);
  HeaderPrompt(6);
  DrawText(false, 24, 220, 'ИНФОРМАЦИЯ О ИГРЕ');
  DrawText(false, 2, 240, 'Игpа КВ2, веpс.1.00');
  DrawText(false, 2, 250, 'По мотивам King"s Bounti, New World Computing, Inc.');
  DrawText(false, 2, 270, 'Сделал : Сеpгей Пpокофьев.');
  DrawText(false, 2, 280, 'Отладил: Андpей Сало (ДЕД).');
  DrawText(false, 2, 290, AuthorContact);
  DrawText(false, 2, 306, 'Пpимечание: Клавиши "Начальник идет" нет.');
  Game.Runtime.LastScan := ReadScanCode;
end;
end.
