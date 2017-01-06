Configuration TeamCity
{
    param(
        $ApiKey,
        $OctopusServerUrl
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName OctopusDSC
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
        Script 'Octopus Tentacle Name'
        {
            SetScript = {
                if ((Get-Service 'OctopusDeploy Tentacle' -ErrorAction Ignore | % Status) -ne 'Running' -or -not (Test-Path "$($env:SystemDrive)\Octopus\Octopus.DSC.installstate")) { return }
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" deregister-from --instance=Tentacle --server="$($using:OctopusServerUrl)" --apikey="$($using:ApiKey)" --console -m | Add-Content -Path 'C:\Octopus\logs\rename.log'
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" register-with --instance=Tentacle --server="$($using:OctopusServerUrl)" --apikey="$($using:ApiKey)" --console --environment='Microsoft Azure' --role='TeamCity Server (Windows)' --name='TeamCity Server' | Add-Content -Path 'C:\Octopus\logs\rename.log'
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
                & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:version).tar.gz" -o"D:\TeamCity-$($using:version)"
                & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:version)\TeamCity-$($using:version).tar" -o"C:\"
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
}