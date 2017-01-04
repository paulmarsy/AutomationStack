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

            # Registration - all parameters required
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = 'Microsoft Azure'
            Roles = "TeamCity Server (Windows)"
            DependsOn = @('[xFirewall]OctopusTentacleFirewall','[Environment]TeamCityDataDir')
        }
        Script 'Octopus Tentacle Name'
        {
            SetScript = {
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" deregister-from --instance=Tentacle --server=$($using:OctopusServerUrl) --apikey=$($using:ApiKey) -m | Write-Output
                & "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" register-with --instance=Tentacle --server=$($using:OctopusServerUrl) --apikey=$($using:ApiKey) --environment='Microsoft Azure' --role='TeamCity Server (Windows)' --name='TeamCity Server' | Write-Output
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
        $version = '10.0.4'
        xRemoteFile TeamCityDownloader
        {
            Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($version).tar.gz"
            DestinationPath = "D:\TeamCity-$($version).tar.gz"
        }
        Archive TeamCityExtract
        {
            Path = "D:\TeamCity-$($version).tar.gz"
            Destination = "C:\"
            DependsOn = "[xRemoteFile]TeamCityDownloader"
        }
        
        $BundleId = "216432" # jre-8u111-windows-i586.exe
        xRemoteFile JreDownloader
        {
            Uri = "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=$BundleId"
            DestinationPath = "D:\JreInstall$BundleId.exe"
        }
        Package Installer
        {
            Ensure = 'Present'
            Name = "Java 8"
            Path = "D:\JreInstall$BundleId.exe"
            Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 /l*v `"D:\JreInstall$BundleId.log`""
            ProductId = "26A24AE4-039D-4CA4-87B4-2F64180101F0"
            DependsOn = "[xRemoteFile]JreDownloader"
        }
        Environment TeamCityDataDir
        {
            Ensure = "Present" 
            Name = "TEAMCITY_DATA_PATH"
            Value = "${env:ALLUSERSPROFILE}\JetBrains\TeamCity"
        }
    }
}