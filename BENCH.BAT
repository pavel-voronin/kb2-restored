@echo off
if "%1"=="" goto usage
if exist BENCH\READY.OK del BENCH\READY.OK
if not exist SRC\BUILD.OK goto nobuild
PASCAL\TPC.EXE BENCH\BREPORT.PAS /B /L /EBENCH > BENCH\REPORT.LOG
if errorlevel 1 goto error
PASCAL\TPC.EXE BENCH\BPREP.PAS /B /L /EBENCH > BENCH\PREP.LOG
if errorlevel 1 goto error
BENCH\BPREP.EXE /COPY %1 > BENCH\COPY.LOG
if errorlevel 1 goto error
cd BENCH\WORK\REF
..\..\..\PASCAL\TPC.EXE KB2.PAS /B /L > ..\..\REFGAME.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE ..\DATA\REFGAME.EXE > NUL
cd ..\..\..
copy /b SRC\DIST\KB2.EXE BENCH\WORK\DATA\CURGAME.EXE > NUL
BENCH\BPREP.EXE /PATCH %1 > BENCH\PATCH.LOG
if errorlevel 1 goto error
cd BENCH\WORK\REF
..\..\..\PASCAL\TPC.EXE KB2.PAS /B /L > ..\..\BREF.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE ..\DATA\BREF.EXE > NUL
..\..\..\PASCAL\TPC.EXE KB2.PAS /B /L /DBCOUNT > ..\..\REFCNT.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE ..\DATA\REFCNT.EXE > NUL
cd ..\CUR
..\..\..\PASCAL\TPC.EXE KB2.PAS /B /L > ..\..\BCUR.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE ..\DATA\BCUR.EXE > NUL
..\..\..\PASCAL\TPC.EXE KB2.PAS /B /L /DBCOUNT > ..\..\CURCNT.LOG
if errorlevel 1 goto suberr
copy /b KB2.EXE ..\DATA\CURCNT.EXE > NUL
cd ..\..\..
echo OK> BENCH\READY.OK
echo Benchmark builds ready. Run BRUN at the chosen CPU speed.
goto end
:suberr
cd ..\..\..
:error
echo Benchmark build failed. See BENCH logs.
goto end
:nobuild
echo Run BUILD first.
goto end
:usage
echo Usage: BENCH reference-root
:end
