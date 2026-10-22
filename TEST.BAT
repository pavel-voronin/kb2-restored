@echo off
if not exist SRC\BUILD.OK goto nobuild
cd SRC
..\PASCAL\TPC.EXE ..\TEST\REGRESS.PAS /B /L /U. /E..\TEST
if errorlevel 1 goto compileerr
cd DIST
..\..\TEST\REGRESS.EXE
if errorlevel 1 goto testerr
type REGRESS.LOG
cd ..\..
echo Regression checks passed.
goto end
:nobuild
echo Run BUILD first.
goto end
:compileerr
cd ..
echo Test compilation failed.
goto end
:testerr
cd ..\..
echo Regression checks failed.
:end
