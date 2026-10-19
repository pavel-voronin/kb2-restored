@echo off
if exist SRC\BUILD.OK del SRC\BUILD.OK
if exist SRC\BUILD.ERR del SRC\BUILD.ERR
if not exist PASCAL\TPC.EXE goto notools
if not exist PASCAL\TURBO.TPL goto notools
if not exist SRC\DIST\NUL mkdir SRC\DIST
cd SRC
..\PASCAL\TPC.EXE KB2.PAS /B /L > GAME.LOG
if errorlevel 1 goto suberr
..\PASCAL\TPC.EXE RSPACK.PAS /B /L > RSPACK.LOG
if errorlevel 1 goto suberr
RSPACK.EXE > PACK.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE DIST\KB2.EXE > COPY.LOG
if errorlevel 1 goto suberr
copy /b DOC\KB2.DOC DIST\KB2.DOC >> COPY.LOG
if errorlevel 1 goto suberr
copy /b DOC\MAPS.TXT DIST\MAPS.TXT >> COPY.LOG
if errorlevel 1 goto suberr
cd ..
echo OK> SRC\BUILD.OK
echo Complete DOS build finished.
goto end
:notools
echo Turbo Pascal 7.0 TPC.EXE and TURBO.TPL are required in PASCAL.
goto error
:suberr
cd ..
:error
echo FAILED> SRC\BUILD.ERR
echo Build failed. See SRC log files.
:end
