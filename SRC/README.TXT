KING'S BOUNTY 2 - CONTINUED

Пути ниже указаны относительно SRC.
Подробное устройство и проверки: DEVELOP.md в корне проекта.

KB2.PAS      - точка входа.
KBADVENT.PAS - общие операции приключения.
KBAPP.PAS    - фазы основного цикла и обработка команд.
KBARMY.PAS   - просмотр и перестановка армии.
KBART.PAS    - изображения существ и память графических буферов.
KBBAI.PAS    - выбор целей и ход противника.
KBBATTLE.PAS - подготовка, цикл и завершение боя.
KBBDMG.PAS   - атаки, урон и потери.
KBBDRAW.PAS  - клетки поля боя и выбор позиции.
KBBMAGIC.PAS - боевая магия.
KBBRES.PAS   - резервы и подчинение.
KBBSCENE.PAS - ландшафт боя и помощь.
KBBTYPE.PAS  - рабочие структуры боя.
KBCAL.PAS    - неделя, расходы и подкрепления.
KBCASTLE.PAS - замки, осада и гарнизоны.
KBDWELL.PAS  - жилища и найм.
KBECON.PAS   - платежи и покупка количества.
KBEVENTS.PAS - чёрный колдун, говорящие камни и мастерская.
KBFILES.PAS  - DOS-чтение ресурсов и копирование кадров.
KBGEN.PAS    - подготовка и генерация новой кампании.
KBGFX.PAS    - низкоуровневая графика EGA.
KBHELP.PAS   - помощь и сведения об игре.
KBHERO.PAS   - команды героя, груз, переходы и сводки.
KBHUD.PAS    - показатели золота, магии и карты.
KBINIT.PAS   - начальные значения состояния.
KBINPUT.PAS  - клавиатура BIOS.
KBLOAD.PAS   - восстановление рабочих данных загруженной кампании.
KBLPT.PAS    - явная настройка принтера.
KBMAGIC.PAS  - магия приключения.
KBMAP.PAS    - просмотр и печать карты.
KBMOTION.PAS - движение армий и открытие карты.
KBPLAYER.PAS - действия и выбор отрядов игрока.
KBRANDOM.PAS - часы или фиксированное зерно случайности.
KBREPORT.PAS - отчёты об армии, контрактах и островах.
KBSAVE.PAS   - прежний формат сохранения кампании.
KBSAVEUI.PAS - ввод имени сохранения.
KBSCROLL.PAS - бумажные свитки.
KBSESS.PAS   - режим экрана, итог боя и завершение игры.
KBSOUND.PAS  - звуковые сигналы.
KBSTART.PAS  - запуск, начальное меню и загрузка графики.
KBSTATE.PAS  - кампания, временное состояние и рабочие данные мира.
KBTABLES.PAS - определения существ, тексты и игровые таблицы.
KBTOWN.PAS   - города, торговля и корабли.
KBTYPES.PAS  - общие типы предметной области.
KBUI.PAS     - окна, подсказки и сообщения.
KBVIEW.PAS   - видимая область приключения.
KBVISIT.PAS  - встречи и события клеток карты.
KBWIZARD.PAS - посещение волшебника.
KBWORKER.PAS - работники и изменение ландшафта.
KBWORLD.PAS  - размещение объектов и переходы между островами.
RSPACK.PAS   - упаковщик картинок и шрифта.

PACK.LST     - список картинок и числа кадров.
README.TXT   - этот перечень.

ART/ - графика и шрифт PCX, 16 цветов EGA:
  ART\ARMY0.PCX
  ART\ARMY1.PCX
  ART\ARMY2.PCX
  ART\ARMY3.PCX
  ART\ARMY4.PCX
  ART\ARMY5.PCX
  ART\CHARM.PCX
  ART\DESERT.PCX
  ART\ENEMY.PCX
  ART\FONT.PCX
  ART\MONEY.PCX
  ART\MOUNTAIN.PCX
  ART\STATUS.PCX
  ART\SUBJECT1.PCX
  ART\SUBJECT2.PCX
  ART\TITL.PCX
  ART\TOWN.PCX
  ART\WATER.PCX
  ART\WOOD.PCX
  ART\YOULOSE.PCX

DOC\KB2.DOC  - оригинальная инструкция к игре.
DOC\MAPS.TXT - оригинальные заготовки карт.

BUILD и RUN запускаются из корня проекта; TEST - проверки.
Проверочные программы находятся отдельно в TEST.
Исходники сохраняются в CP866 с CRLF, имена - DOS 8.3.
