param(
 [Parameter(Mandatory=$true)][string]$Commands,
 [Parameter(Mandatory=$true)][string]$Work,
 [string]$DosBox=$env:KB2_DOSBOX,
 [int]$TimeoutSeconds = 600
)
$ErrorActionPreference='Stop'
if (-not $DosBox) { $DosBox=(Get-Command dosbox-x -ErrorAction Stop).Source }
$Work=[IO.Path]::GetFullPath($Work)
$conf=@"
[sdl]
output=surface
[dosbox]
machine=ega
memsize=16
[cpu]
core=dynamic
cycles=max
[video]
vmemsize=0
vmemsizekb=256
[mixer]
nosound=true
[autoexec]
mount c "$Work"
c:
config -securemode
$Commands
exit
"@
$configPath=Join-Path $Work 'SOLVER.CNF'
[IO.File]::WriteAllText($configPath,($conf -replace "`r?`n","`r`n"),[Text.Encoding]::ASCII)
$info=[Diagnostics.ProcessStartInfo]::new()
$info.FileName=[IO.Path]::GetFullPath($DosBox)
$info.Arguments='-conf "'+$configPath+'" -fastlaunch -nogui -exit'
$info.WorkingDirectory=$Work
$info.UseShellExecute=$false
$info.CreateNoWindow=$true
$info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$info.RedirectStandardOutput=$true
$info.RedirectStandardError=$true
$info.EnvironmentVariables['SDL_VIDEODRIVER']='dummy'
$info.EnvironmentVariables['SDL_AUDIODRIVER']='dummy'
$p=[Diagnostics.Process]::Start($info)
$kb2ParentAffinity=(Get-Process -Id $PID).ProcessorAffinity.ToInt64()
$kb2FirstCpu=$kb2ParentAffinity -band (-$kb2ParentAffinity)
$kb2OtherCpus=$kb2ParentAffinity -band (-bnot $kb2FirstCpu)
$kb2CpuMask=$kb2FirstCpu -bor ($kb2OtherCpus -band (-$kb2OtherCpus))
$p.ProcessorAffinity=[IntPtr]$kb2CpuMask
$p.PriorityClass='BelowNormal'
$outTask=$p.StandardOutput.ReadToEndAsync()
$errTask=$p.StandardError.ReadToEndAsync()
if (-not $p.WaitForExit($TimeoutSeconds*1000)) { $p.Kill(); throw 'Replay timed out' }
$null=$outTask.Result
$null=$errTask.Result
if ($p.ExitCode -ne 0) { throw 'DOSBox failed' }
