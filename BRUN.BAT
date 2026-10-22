@echo off
if not exist BENCH\READY.OK goto nobuild
if not exist BENCH\WORK\DATA\CURCNT.EXE goto nobuild
cd BENCH\WORK\DATA
BREF.EXE %1
if errorlevel 1 goto error
BCUR.EXE %1
if errorlevel 1 goto error
REFCNT.EXE
if errorlevel 1 goto error
CURCNT.EXE
if errorlevel 1 goto error
..\..\BREPORT.EXE
if errorlevel 1 goto error
cd ..\..\..
echo Benchmark CSV files are in BENCH\WORK\DATA.
goto end
:error
cd ..\..\..
echo Benchmark run failed.
goto end
:nobuild
echo Run BUILD and BENCH reference-root first.
:end
