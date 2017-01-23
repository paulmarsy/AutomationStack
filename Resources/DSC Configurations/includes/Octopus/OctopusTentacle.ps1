xFirewall OctopusDeployTentacle
{
    Name                  = "OctopusTentacle"
    DisplayName           = "Octopus Deploy Tentacle"
    Ensure                = "Present"
    Enabled               = "True"
    Action                = "Allow"
    Profile               = "Any"
    Direction             = "InBound"
    LocalPort             = "10933"
    Protocol              = "TCP"
}
$octopusDeployRoot =  "$($env:SystemDrive)\Octopus\DSC"     
File OctopusDeployFolder {
    Type = 'Directory'
    DestinationPath = $octopusDeployRoot
    Ensure = "Present"
}

$octopusInstallFile = Join-Path $octopusDeployRoot "OctopusTentacle.msi"
xRemoteFile OctopusTentacle
{
    Uri = 'https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle'
    DestinationPath = $octopusInstallFile
    MatchSource = $false
    DependsOn = '[File]OctopusDeployFolder'
}
$octopusInstallLogFile = Join-Path $octopusDeployRoot "OctopusTentacle.install.log"
$octopusInstallStateFile = Join-Path $octopusDeployRoot 'OctopusDeploy.install'
Script OctopusTentacleInstall
{
    SetScript = {
        $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($using:octopusInstallFile)`"  /quiet /l*v `"$($using:octopusInstallLogFile)`"" -Wait -Passthru).ExitCode
        if ($msiExitCode -ne 0)
        {
            throw "Installation of Octopus Tentacle failed; MSIEXEC exited with code: $msiExitCode"
        }
        [System.IO.FIle]::WriteAllText($using:octopusInstallStateFile, $msiExitCode, [System.Text.Encoding]::ASCII)
    }
    TestScript = {
        ((Test-Path $using:octopusInstallStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusInstallStateFile).Trim()) -eq '0')
    }
    GetScript = { @{} }
    DependsOn = '[xRemoteFile]OctopusTentacle'
}
$octopusConfigStateFile = Join-Path $octopusDeployRoot 'OctopusDeploy.config'
$octopusConfigLogFile = Join-Path $octopusDeployRoot "OctopusTentacle.config.log"
Script OctopusTentacleConfiguration
{
    SetScript = {
        $octopusTentacleExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Tentacle\Tentacle.exe'

        & $octopusTentacleExe create-instance --console --instance "Tentacle" --config "C:\Octopus\Tentacle.config" *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: create-instance" }
        & $octopusTentacleExe new-certificate --console --instance "Tentacle" *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: new-certificate" }
        & $octopusTentacleExe configure --console --instance "Tentacle" --reset-trust *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: reset-trust" }
        & $octopusTentacleExe configure --console --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --port "10933" --noListen "False" *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: configure" }
        & $octopusTentacleExe register-with --console --instance "Tentacle" --server $using:OctopusServerUrl --apikey="$($using:OctopusApiKey)"  --role="$($using:Node.Octopus.Role)" --environment="$($using:Node.Octopus.Environment)" --name="$($using:Node.Octopus.Name)" --comms-style TentaclePassive *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: register-with" }
        & $octopusTentacleExe service --console --instance "Tentacle" --install --start *>> $using:octopusConfigLogFile
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: service" }
        
        Start-Service OctopusDeploy *>> $using:octopusConfigLogFile
        [System.IO.FIle]::WriteAllText($using:octopusConfigStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
    }
    TestScript = {
        ((Test-Path $using:octopusConfigStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusConfigStateFile).Trim()) -eq '0')
    }
    GetScript = { @{} }
    DependsOn = @('[xFirewall]OctopusDeployTentacle','[Script]OctopusTentacleInstall')
}