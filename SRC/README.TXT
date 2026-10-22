KING'S BOUNTY 2 - CONTINUE

Карта модулей и план рефакторинга: DEVELOP.md в корне проекта.

KB2.PAS      - точка входа.
KBAPP.PAS    - основной цикл и команды приключения.
KBSTART.PAS  - запуск, начальное меню и загрузка графики.
KBTYPES.PAS  - общие типы предметной области.
KBSTATE.PAS  - состояние игры; старый порядок полей пока сохранён.
KBTABLES.PAS - определения существ, тексты и игровые таблицы.
KBINPUT.PAS  - клавиатура BIOS.
KBRANDOM.PAS - случайность и фиксированное зерно для проверок.
KBFILES.PAS  - чтение ресурсов DOS и копирование кадров.
KBART.PAS    - загрузка изображений существ.
KBGFX.PAS    - графика EGA и старые процедуры движения на карте.
KBUI.PAS     - окна, подсказки, сообщения и подписи.
KBVIEW.PAS   - вывод области приключения.
KBSAVE.PAS   - чтение и запись кампании.
KBWORKER.PAS - работники и изменение ландшафта.
KBCAL.PAS    - недельные расходы, население и подкрепления.
KBWORLD.PAS  - подготовка кампании, острова и размещение армий.
  WORLDGEN.INC - создание островов и их населения.
KBADVENT.PAS - общие команды приключения и встречи.
  TOWN.INC, WIZARD.INC, SCROLL.INC, DWELLING.INC, MAP.INC.
KBCAMPGN.PAS - магия приключения, исход боя и завершение игры.
  ARMY.INC, CASTLE.INC.
KBEVENTS.PAS - чёрный колдун, говорящие камни и мастерская.
KBBATTLE.PAS - бой; KBBTYPE.PAS - его рабочие структуры.
  COMBAT.INC, BATDRAW.INC, DAMAGE.INC, PLAYER.INC,
  ENEMYAI.INC, BATMAGIC.INC, RESERVES.INC.
KBSOUND.PAS  - звуковые сигналы.
KBLPT.PAS    - настройка печати.
RSPACK.PAS   - упаковка PCX по списку PACK.LST.

ART/ - графика и шрифт PCX, 16 цветов EGA.
DOC/ - оригинальные KB2.DOC и MAPS.TXT, без изменений.

BUILD и RUN запускаются из корня проекта; TEST - проверки.
Исходники сохраняются в CP866 с CRLF, имена - DOS 8.3.
