Configuration TeamCity
{
    param(
        $OctopusServerUrl,
        $OctopusApiKey,
        $OctopusEnvironment,
        $OctopusRole,
        $OctopusDisplayName
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    
    Node "Server"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"
            Name = "Tentacle"
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = 'Microsoft Azure'
            Roles = "TeamCity Server (Windows)"
            DependsOn = @('[xFirewall]OctopusTentacleFirewall','[Environment]TeamCityDataDir','[Environment]JavaHome')
        }
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
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: create-instance" }
                & $octopusTentacleExe new-certificate --console --instance "Tentacle" *>> $using:octopusConfigLogFile
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: new-certificate" }
                & $octopusTentacleExe configure --console --instance "Tentacle" --reset-trust *>> $using:octopusConfigLogFile
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: reset-trust" }
                & $octopusTentacleExe configure --console --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --port "10933" --noListen "False" *>> $using:octopusConfigLogFile
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: configure" }
                & $octopusTentacleExe register-with --console --instance "Tentacle" --server $using:OctopusServerUrl --apikey="$($using:OctopusApiKey)"  --role="$($using:OctopusEnvironment)" --environment="$($using:OctopusEnvironment)" --name="$($using:OctopusDisplayName)" --comms-style TentaclePassive *>> $using:octopusConfigLogFile
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: register-with" }
                & $octopusTentacleExe service --console --instance "Tentacle" --install --start *>> $using:octopusConfigLogFile
                if ($LASTEXITCODE -gt 0) { throw "Exit code $LASTEXITCODE from Octopus Tentacle: service" }
                
                Start-Service OctopusDeploy *>> $using:octopusConfigLogFile
                [System.IO.FIle]::WriteAllText($using:octopusConfigStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:octopusConfigStateFile) -and ([System.IO.FIle]::ReadAllText($using:octopusConfigStateFile).Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = @('[xFirewall]OctopusDeployTentacle','[Script]OctopusTentacleInstall')
        }




        
        xFirewall TeamCityServerFirewall
        {
            Name                  = "TeamCityServer"
            DisplayName           = "TeamCity Server"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = "Allow"
            Profile               = "Any"
            Direction             = "InBound"
            LocalPort             = ("80", "444")
            Protocol              = "TCP"
        }

        xRemoteFile SevenZipDownloader
        {
            Uri = 'http://www.7-zip.org/a/7z1604-x64.msi'
            DestinationPath = 'D:\7z1604-x64.msi'
        }
        Package SevenZip
        {
            Ensure = 'Present'
            Path = 'D:\7z1604-x64.msi'
            Name = '7-Zip 16.04 (x64 edition)'
            Arguments = "/qn /l*v `"D:\7ZipInstall.log`""
            ProductId = '23170F69-40C1-2702-1604-000001000000'
            DependsOn = "[xRemoteFile]SevenZipDownloader"
        }
        
        Script JDKDownloader
        {
            SetScript = {
                $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                $cookie = New-Object System.Net.Cookie 
                $cookie.Name = "oraclelicense"
                $cookie.Value = "accept-securebackup-cookie"
                $cookie.Domain = ".oracle.com"
                $session.Cookies.Add($cookie);
                $uri = 'http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-windows-i586.exe'
                Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $session -OutFile 'D:\JDKInstall.exe'
            }
            TestScript = {
                (Test-Path 'D:\JDKInstall.exe')
            }
            GetScript = { @{} }
        }
        $javaInstallPath = 'C:\jdk8'
        $id = "180112"
        Package Java
        {
            Ensure = 'Present'
            Name = "Java SE Development Kit 8 Update 112"
            Path = "D:\JDKInstall.exe"
            Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 INSTALLDIR=`"$javaInstallPath`" /l*v `"D:\JDKInstall.log`""
            ProductID = "32A3A4F4-B792-11D6-A78A-00B0D0${id}"
            DependsOn = "[Script]JDKDownloader"
        }

        $version = '10.0.4'
        xRemoteFile TeamCityDownloader
        {
            Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($version).tar.gz"
            DestinationPath = "D:\TeamCity-$($version).tar.gz"
        }
        Script TeamCityExtract
        {
            SetScript = {
                & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:version).tar.gz" -o"D:\"
                & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:version).tar" -o"C:\"
            }
            TestScript = {
                (Test-Path "$($env:SystemDrive)\TeamCity\BUILD_42538")
            }
            GetScript = { @{} }
            DependsOn = @("[xRemoteFile]TeamCityDownloader","[Package]SevenZip")
        }
        Script TeamCityServerConfig
        {
            SetScript = {
                Move-Item -Path "$($env:SystemDrive)\TeamCity\conf\server.xml" -Destination "$($env:SystemDrive)\TeamCity\conf\server.xml.dscbackup"
				$serverConfigFile = [System.IO.File]::ReadAllText("$($env:SystemDrive)\TeamCity\conf\server.xml.dscbackup")
				$serverConfigFile = $serverConfigFile.Replace(' port="8111" ', ' port="80" ')
				[System.IO.File]::WriteAllText("$($env:SystemDrive)\TeamCity\conf\server.xml", $serverConfigFile, [System.Text.Encoding]::ASCII)

            }
            TestScript = {
                (Test-Path "$($env:SystemDrive)\TeamCity\conf\server.xml.dscbackup")
            }
            GetScript = { @{} }
            DependsOn = '[Script]TeamCityExtract'
        }

        Environment TeamCityDataDir
        {
            Ensure = "Present" 
            Name = "TEAMCITY_DATA_PATH"
            Value = "${env:ALLUSERSPROFILE}\JetBrains\TeamCity"
        }
        Environment JavaHome
        {
            Ensure = "Present" 
            Name = "JAVA_HOME"
            Value = $javaInstallPath
        }
    }

    Node CloudAgent
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"
            Name = "Tentacle"
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = 'Agent Cloud'
            Roles = "TeamCity Agent Image"
            DependsOn = @('[xFirewall]OctopusTentacleFirewall','[Environment]JavaHome')
        }
        Script 'Octopus Tentacle Name'
        {
            SetScript = {
                if ((Get-Service 'OctopusDeploy Tentacle' -ErrorAction Ignore | % Status) -ne 'Running' -or -not (Test-Path "$($env:SystemDrive)\Octopus\Octopus.DSC.installstate")) { return }
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" deregister-from --instance=Tentacle --server="$($using:OctopusServerUrl)" --apikey="$($using:ApiKey)" --console -m | Add-Content -Path 'C:\Octopus\logs\rename.log'
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" register-with --instance=Tentacle --server="$($using:OctopusServerUrl)" --apikey="$($using:ApiKey)" --console --environment='Agent Cloud' --role='TeamCity Agent Image' --name='TeamCity Agent Cloud Blueprint' | Add-Content -Path 'C:\Octopus\logs\rename.log'
                [System.IO.FIle]::WriteAllText("$($env:SystemDrive)\Octopus\Octopus.Server.DSC.regstate", $LASTEXITCODE,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.regstate") -and ([System.IO.FIle]::ReadAllText("$($env:SystemDrive)\Octopus\Octopus.Server.DSC.regstate").Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = '[cTentacleAgent]OctopusTentacle'
        }
        xFirewall OctopusTentacleFirewall
        {
            Name                  = "OctopusTentacle"
            DisplayName           = "Octopus Tentacle"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = "Allow"
            Profile               = "Any"
            Direction             = "InBound"
            LocalPort             = "10933"
            Protocol              = "TCP"
        }
        xFirewall TeamCityAgentFirewall
        {
            Name                  = "TeamCityAgent"
            DisplayName           = "TeamCity Agent"
            Ensure                = "Present"
            Enabled               = "True"
            Action                = "Allow"
            Profile               = "Any"
            Direction             = "InBound"
            LocalPort             = "9090"
            Protocol              = "TCP"
        }

        xRemoteFile SevenZipDownloader
        {
            Uri = 'http://www.7-zip.org/a/7z1604-x64.msi'
            DestinationPath = 'D:\7z1604-x64.msi'
        }
        Package SevenZip
        {
            Ensure = 'Present'
            Path = 'D:\7z1604-x64.msi'
            Name = '7-Zip 16.04 (x64 edition)'
            Arguments = "/qn /l*v `"D:\7ZipInstall.log`""
            ProductId = '23170F69-40C1-2702-1604-000001000000'
            DependsOn = "[xRemoteFile]SevenZipDownloader"
        }
        
        Script JDKDownloader
        {
            SetScript = {
                $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                $cookie = New-Object System.Net.Cookie 
                $cookie.Name = "oraclelicense"
                $cookie.Value = "accept-securebackup-cookie"
                $cookie.Domain = ".oracle.com"
                $session.Cookies.Add($cookie);
                $uri = 'http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-windows-i586.exe'
                Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $session -OutFile 'D:\JDKInstall.exe'
            }
            TestScript = {
                (Test-Path 'D:\JDKInstall.exe')
            }
            GetScript = { @{} }
        }
        $javaInstallPath = 'C:\jdk8'
        $id = "180112"
        Package Java
        {
            Ensure = 'Present'
            Name = "Java SE Development Kit 8 Update 112"
            Path = "D:\JDKInstall.exe"
            Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 INSTALLDIR=`"$javaInstallPath`" /l*v `"D:\JDKInstall.log`""
            ProductID = "32A3A4F4-B792-11D6-A78A-00B0D0${id}"
            DependsOn = "[Script]JDKDownloader"
        }

        $version = '10.0.4'
        xRemoteFile TeamCityDownloader
        {
            Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($version).tar.gz"
            DestinationPath = "D:\TeamCity-$($version).tar.gz"
        }
        Script TeamCityExtract
        {
            SetScript = {
                & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:version).tar.gz" -o"D:\"
                & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:version).tar" -o"D:\"
                Copy-Item -Path 'D:\TeamCity\buildAgent' -Destination C:\ -Recurse
            }
            TestScript = {
                (Test-Path "$($env:SystemDrive)\buildAgent\BUILD_42538")
            }
            GetScript = { @{} }
            DependsOn = @("[xRemoteFile]TeamCityDownloader","[Package]SevenZip")
        }
        Environment JavaHome
        {
            Ensure = "Present" 
            Name = "JAVA_HOME"
            Value = $javaInstallPath
        }
    }
}