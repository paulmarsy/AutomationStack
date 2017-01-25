Configuration OctopusDeploy
{
    param(
        $OctopusNodeName,
        $ConnectionString,
        $HostHeader,
        $FullyQualifiedUrl,
        $OctopusVersionToInstall = 'latest'
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xSystemSecurity

    $octopusDeployServiceAccount = Get-AutomationPSCredential -Name 'OctopusDeployServiceAccount'

    Node Server
    {
        #include <Common>

        xFirewall OctopusDeployServer
        {
            Name                  = "OctopusServer"
            DisplayName           = "Octopus Deploy Server"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = "Allow"
            Profile               = "Any"
            Direction             = "InBound"
            LocalPort             = ("80", "10943")
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
            MatchSource = $false
            DependsOn = '[File]OctopusDeployFolder'
        }

        $octopusInstallLogFile = Join-Path $octopusDeployRoot "OctopusServer.$OctopusVersionToInstall.install.log"
        $octopusInstallStateFile = Join-Path $octopusDeployRoot 'version.statefile'
        Script OctopusDeployInstall
        {
            SetScript = {
                Get-Service OctopusDeploy -ErrorAction Ignore | Stop-Service OctopusDeploy -Force -Verbose | Write-Verbose
                $isUpgrade = $false
                if (Test-Path $using:octopusInstallStateFile) {
                    $currentVersion = [System.IO.FIle]::ReadAllText($using:octopusInstallStateFile).Trim()
                    if ($currentVersion -ne $using:OctopusVersionToInstall) {
                        Write-Verbose 'Uninstalling current Octopus install'
                        $isUpgrade = $true
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
                }
                Write-Verbose 'Starting Octopus MSI installer..'
                $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($using:octopusInstallFile)`"  /quiet /l*v `"$($using:octopusInstallLogFile)`"" -Wait -Passthru).ExitCode
                if ($msiExitCode -ne 0)
                {
                    throw "Installation of Octopus Deploy failed; MSIEXEC exited with code: $msiExitCode"
                }
                if ($isUpgrade) {
                   Start-Service OctopusDeploy -Verbose | Write-Verbose
                }
                [System.IO.FIle]::WriteAllText($using:octopusInstallStateFile, $using:OctopusVersionToInstall,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusInstallStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusInstallStateFile).Trim()) -eq $using:OctopusVersionToInstall)
            }
            GetScript = { @{} }
            DependsOn = '[xRemoteFile]OctopusServer'
        }

        $octopusConfigStateFile = Join-Path $octopusDeployRoot 'configuration.statefile'
        $octopusConfigLogFile = Join-Path $octopusDeployRoot "OctopusServer.$OctopusVersionToInstall.config.log"
        Script OctopusDeployConfiguration
        {
            SetScript = {
                $octopusServerExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Octopus\Octopus.Server.exe'

                & $octopusServerExe create-instance --console --instance OctopusServer --config "$($env:SystemDrive)\Octopus\OctopusServer.config" *>&1  | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server: create-instance" }
                & $octopusServerExe configure --console --instance OctopusServer --home "C:\Octopus" --storageConnectionString $using:ConnectionString --upgradeCheck "True" --upgradeCheckWithStatistics "True" --webAuthenticationMode "UsernamePassword" --webForceSSL "False" --webListenPrefixes $using:HostHeader --commsListenPort "10943" --serverNodeName $using:OctopusNodeName *>&1   | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server: configure" }
                & $octopusServerExe database --console --instance OctopusServer --create *>&1   | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server: database" }
                
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://octopusdeploy.com/api/licenses/trial" -Method POST -Body @{ FullName=$env:USERNAME; Organization=$env:USERDOMAIN; EmailAddress="${env:USERNAME}@${env:USERDOMAIN}.onmicrosoft.com"; Source="azure" } -Verbose
                $licenseBase64 = [System.Convert]::ToBase64String(((New-Object System.Text.UTF8Encoding($false)).GetBytes($response.Content)))
                & $octopusServerExe license --console --instance OctopusServer --licenseBase64 $licenseBase64 *>&1   | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server: license" }

                & $octopusServerExe service --console --instance OctopusServer --install --reconfigure --stop *>&1   | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server: service" }

                [System.IO.FIle]::WriteAllText($using:octopusConfigStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusConfigStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusConfigStateFile).Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = '[Script]OctopusDeployInstall'
        }

        $octopusServiceAccountUsername = $octopusDeployServiceAccount.UserName
        User OctopusDeployServiceAccount
        {
            UserName                = $octopusServiceAccountUsername
            Password                = $octopusDeployServiceAccount
            PasswordChangeRequired  = $false
            PasswordNeverExpires    = $true
        }
        Script SetOctopusUserGroups
        {
            SetScript = {
                $user = Get-LocalUser -Name $using:octopusServiceAccountUsername
                Add-LocalGroupMember -Name Users -Member $user
            }
            TestScript = {
                $user = Get-LocalUser -Name $using:octopusServiceAccountUsername
                ($null -ne (Get-LocalGroupMember -Name Users -Member $user -ErrorAction Ignore))
            }
            GetScript = { @{} }
            DependsOn = '[User]OctopusDeployServiceAccount'
        }

        Service OctopusDeploy
        {
            Name        = 'OctopusDeploy'
            Credential  = $octopusDeployServiceAccount
            StartupType = 'Automatic'
            DependsOn = @('[User]OctopusDeployServiceAccount','[Script]OctopusDeployConfiguration')
        } 

        $octopusUrlAclStateFile = Join-Path $octopusDeployRoot 'urlacl.statefile'
        Script URLAccessControlList
        {
            SetScript = {
                $netsh = Join-Path -Resolve ([System.Environment]::SystemDirectory) 'netsh.exe'
                Write-Verbose "Found $netsh"

                Write-Verbose 'Removing existing URL access control entries for HTTP'
                & $netsh http delete urlacl url=http://+:80/ *>&1 |  Write-Verbose
                if ($LASTEXITCODE -notin @(0, 1)) { throw "Exit code $LASTEXITCODE from netsh delete urlacl" }
                
                $username = '{0}\{1}' -f [System.Environment]::MachineName, $using:octopusServiceAccountUsername
                Write-Verbose "Adding new HTTP URL acccess control entry for user $username"
                & $netsh http add urlacl url=$using:FullyQualifiedUrl user=$username *>&1 |  Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from netsh add urlacl" }
                
                [System.IO.File]::WriteAllText($using:octopusUrlAclStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusUrlAclStateFile) -and ([System.IO.File]::ReadAllText($using:octopusUrlAclStateFile).Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = '[User]OctopusDeployServiceAccount'
        }

        xFileSystemAccessRule OctopusConfigFile {
            Path = "$($env:SystemDrive)\Octopus\"
            Identity = $octopusServiceAccountUsername
            Rights = @("FullControl")
            DependsOn = @('[User]OctopusDeployServiceAccount','[Script]OctopusDeployConfiguration')
        }

        $octopusServiceStartedStateFile = Join-Path $octopusDeployRoot 'service.statefile'
        Script OctopusServiceStart
        {
            SetScript = {
                Stop-Service OctopusDeploy -Force -Verbose | Write-Verbose
                Start-Service OctopusDeploy -Verbose | Write-Verbose

                [System.IO.FIle]::WriteAllText($using:octopusServiceStartedStateFile, (Get-Service OctopusDeploy | % Status),[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusServiceStartedStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusServiceStartedStateFile).Trim()) -eq 'Running')
            }
            GetScript = { @{} }
            DependsOn = @('[xFirewall]OctopusDeployServer','[Script]URLAccessControlList','[Service]OctopusDeploy','[Script]OctopusDeployConfiguration','[User]OctopusDeployServiceAccount','[Script]SetOctopusUserGroups','[xFileSystemAccessRule]OctopusConfigFile')
        }
    }
}