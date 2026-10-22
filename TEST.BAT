@echo off
if exist TEST\TEST.OK del TEST\TEST.OK
if exist TEST\TEST.ERR del TEST\TEST.ERR
if not exist SRC\BUILD.OK goto nobuild
cd SRC
..\PASCAL\TPC.EXE ..\TEST\REGRESS.PAS /B /L /DSTRUCTURED /U. /E..\TEST
if errorlevel 1 goto compileerr
..\PASCAL\TPC.EXE ..\TEST\TACTIC.PAS /B /L /U. /E..\TEST
if errorlevel 1 goto compileerr
cd DIST
..\..\TEST\REGRESS.EXE
if errorlevel 1 goto testerr
type REGRESS.LOG
..\..\TEST\TACTIC.EXE
if errorlevel 1 goto testerr
type TACTIC.LOG
cd ..\..
echo OK> TEST\TEST.OK
echo Regression checks passed.
goto end
:nobuild
echo Run BUILD first.
goto error
:compileerr
cd ..
echo Test compilation failed.
goto error
:testerr
cd ..\..
echo Regression checks failed.
:error
echo FAILED> TEST\TEST.ERR
:end
