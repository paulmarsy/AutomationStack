Configuration OctopusDeploy
{
    param(
        $OctopusNodeName,
        $ConnectionString,
        $HostHeader,
        $OctopusVersionToInstall = 'latest'
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking

    Node "Server"
    {
        xFirewall OctopusDeployServer
        {
            Name                  = "OctopusServer"
            DisplayName           = "Octopus Server"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = "Allow"
            Profile               = "Any"
            Direction             = "InBound"
            LocalPort             = ("80", "444", "10943")
            Protocol              = "TCP"
        }

        $octopusDeployRoot =  "$($env:SystemDrive)\Octopus\DSC"     
        File OctopusDeployFolder {
            Type = 'Directory'
            DestinationPath = $octopusDeployRoot
            Ensure = "Present"
        }

        if ($OctopusVersionToInstall -eq 'latest') {
            $octopusDownloadUri = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"
        } else {
            $octopusDownloadUri = "https://download.octopusdeploy.com/octopus/Octopus.${OctopusVersionToInstall}-x64.msi"
        }
        $octopusInstallFile = Join-Path $octopusDeployRoot "OctopusServer.$OctopusVersionToInstall.msi"
        xRemoteFile OctopusServer
        {
            Uri = $octopusDownloadUri
            DestinationPath = $octopusInstallFile
            DependsOn = '[File]OctopusDeployFolder'
        }
        $octopusInstallLogFile = Join-Path $octopusDeployRoot "OctopusServer.$OctopusVersionToInstall.install.log"
        $octopusInstallStateFile = Join-Path $octopusDeployRoot 'OctopusDeploy.version'
        Script OctopusDeployInstall
        {
            SetScript = {
                Get-Service OctopusDeploy -ErrorAction Ignore | Stop-Service -Force
                $isUpgrade = $false
                if (Test-Path $using:octopusInstallStateFile) {
                    $isUpgrade = $true
                    $currentVersion = [System.IO.FIle]::ReadAllText($using:octopusInstallStateFile).Trim()
                    $currentOctopusInstallFile = Join-Path $using:octopusDeployRoot "OctopusServer.$currentVersion.msi"
                     if (!(Test-Path $currentOctopusInstallFile)) {
                         throw "Unable to install different Octopus Deploy versiom, previously installed msi file not found: $currentOctopusInstallFile"
                     }

                     $octopusUninstallLogFile = Join-Path $octopusDeployRoot "OctopusServer.$currentVersion.uninstall.log"
                    $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x `"$currentOctopusInstallFile`" /quiet /l*v `"$octopusUninstallLogFile`"" -Wait -Passthru).ExitCode
                    if ($msiExitCode -ne 0)
                    {
                        throw "Uninstallation of Octopus Deploy failed; MSIEXEC exited with code: $msiExitCode"
                    }
                    Remove-Item -Path $using:octopusInstallStateFile -Force
                }
                $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($using:octopusInstallFile)`"  /quiet /l*v `"$($using:octopusInstallLogFile)`"" -Wait -Passthru).ExitCode
                if ($msiExitCode -ne 0)
                {
                    throw "Installation of Octopus Deploy failed; MSIEXEC exited with code: $msiExitCode"
                }
                if ($isUpgrade) {
                    Start-Service OctopusDeploy
                }
                [System.IO.FIle]::WriteAllText($using:octopusInstallStateFile, $using:OctopusVersionToInstall,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusInstallStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusInstallStateFile).Trim()) -eq $using:OctopusVersionToInstall)
            }
            GetScript = { @{} }
            DependsOn = '[xRemoteFile]OctopusServer'
        }
        $octopusConfigStateFile = Join-Path $octopusDeployRoot 'OctopusDeploy.config'
        $octopusConfigLogFile = Join-Path $octopusDeployRoot "OctopusServer.$OctopusVersionToInstall.config.log"
        Script OctopusDeployConfiguration
        {
            SetScript = {
                $octopusServerExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Octopus\Octopus.Server.exe'
                $addativeExitCode = 0
                & $octopusServerExe create-instance --console --instance OctopusServer --config "C:\Octopus\OctopusServer.config" *>> $using:octopusConfigLogFile
                $addativeExitCode += $LASTEXITCODE; if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Server: create-instance" }
                & $octopusServerExe configure --console --instance OctopusServer --home "C:\Octopus" --storageConnectionString $using:ConnectionString --upgradeCheck "True" --upgradeCheckWithStatistics "True" --webAuthenticationMode "UsernamePassword" --webForceSSL "False" --webListenPrefixes $using:HostHeader --commsListenPort "10943" --serverNodeName $using:OctopusNodeName *>> $using:octopusConfigLogFile
                $addativeExitCode += $LASTEXITCODE; if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Server: configure" }
                & $octopusServerExe database --console --instance OctopusServer --create *>> $using:octopusConfigLogFile
                $addativeExitCode += $LASTEXITCODE; if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Server: database" }
                
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://octopusdeploy.com/api/licenses/trial" -Method POST -Body @{ FullName=$env:USERNAME; Organization=$env:USERDOMAIN; EmailAddress="${env:USERNAME}@${env:USERDOMAIN}.com"; Source="azure" }
                $utf8NoBOM = (New-Object System.Text.UTF8Encoding($false)).GetBytes($response.Content)
                $licenseBase64 = [System.Convert]::ToBase64String($bytes)
                & $octopusServerExe license --console --instance OctopusServer --licenseBase64 $licenseBase64 *>> $using:octopusConfigLogFile
                $addativeExitCode += $LASTEXITCODE; if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Server: license" }

                & $octopusServerExe service --console --instance OctopusServer --install --reconfigure --start *>> $using:octopusConfigLogFile
                $addativeExitCode += $LASTEXITCODE; if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Server: service" }
                Start-Service OctopusDeploy *>> $using:octopusConfigLogFile
                [System.IO.FIle]::WriteAllText($using:octopusConfigStateFile, $addativeExitCode,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusConfigStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusConfigStateFile).Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = @('[xFirewall]OctopusDeployServer','[Script]OctopusDeployInstall')
        }
    }
}