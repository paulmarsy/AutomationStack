#$watchdogExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Octopus\Octopus.Server.exe'
#$watchdogExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Tentacle\Tentacle.exe'

$octopusWatchdogStateFile = Join-Path $octopusDeployRoot 'OctopusWatchdog.statefile'
Script OctopusWatchdog
{
    SetScript = {
        & $using:watchdogExe watchdog --create --instances * *>&1 | Write-Verbose
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Watchdog creation" }
 
        [System.IO.FIle]::WriteAllText($using:octopusWatchdogStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
    }
    TestScript = {
        ((Test-Path $using:octopusWatchdogStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusWatchdogStateFile).Trim()) -eq '0')
    }
    GetScript = { @{} }
    DependsOn = '[Script]OctopusDeployConfiguration'
}