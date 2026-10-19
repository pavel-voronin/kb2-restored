@echo off
if not exist SRC\DIST\KB2.EXE goto missing
cd SRC\DIST
KB2.EXE
cd ..\..
goto end
:missing
echo Run BUILD.BAT first.
:end
