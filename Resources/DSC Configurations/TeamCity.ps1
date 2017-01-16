Configuration TeamCity
{
    param(
        $OctopusServerUrl,
        $OctopusApiKey,
        $OctopusEnvironment,
        $OctopusRole,
        $OctopusDisplayName,
        $TeamCityVersion = '10.0.4'
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    
    Node Server
    {
        #include <TeamCityCommon>
        
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

        xRemoteFile TeamCityDownload
        {
            Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($TeamCityVersion).tar.gz"
            DestinationPath = "D:\TeamCity-$($TeamCityVersion).tar.gz"
        }
        Script TeamCityExtract
        {
            SetScript = {
                & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:TeamCityVersion).tar.gz" -o"D:\"
                & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:TeamCityVersion).tar" -o"C:\"
            }
            TestScript = {
                (Test-Path "$($env:SystemDrive)\TeamCity\BUILD_42538")
            }
            GetScript = { @{} }
            DependsOn = @('[xRemoteFile]TeamCityDownload','[Package]SevenZip')
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
    }

    Node CloudAgent
    {
        #include <TeamCityCommon>
        
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

        xRemoteFile TeamCityDownload
        {
            Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($TeamCityVersion).tar.gz"
            DestinationPath = "D:\TeamCity-$($TeamCityVersion).tar.gz"
        }
        Script TeamCityExtract
        {
            SetScript = {
                & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:TeamCityVersion).tar.gz" -o"D:\"
                & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:TeamCityVersion).tar" -o"D:\"
                Copy-Item -Path 'D:\TeamCity\buildAgent' -Destination C:\ -Recurse
            }
            TestScript = {
                (Test-Path "$($env:SystemDrive)\buildAgent\BUILD_42538")
            }
            GetScript = { @{} }
            DependsOn = @('[xRemoteFile]TeamCityDownload','[Package]SevenZip')
        }
    }
}