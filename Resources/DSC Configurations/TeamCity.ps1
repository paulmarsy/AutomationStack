Configuration TeamCity
{
    param(
        $OctopusServerUrl,
        $OctopusApiKey,
        $HostHeader,
        $TeamCityVersion
    )
        
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName PackageManagementProviderResource
    Import-DscResource -ModuleName xSystemSecurity

    Node Server
    {
        #include <Common>
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
            LocalPort             = "80"
            Protocol              = "TCP"
        }

        File TeamCityServerInstall
        {
            DestinationPath = "$($env:SystemDrive)\TeamCity"
            Recurse = $true
            SourcePath = 'D:\TeamCity'
            Type = 'Directory'
            MatchSource = $false
            DependsOn = '[Script]TeamCityExtract'
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
        #include <Common>
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

        File TeamCityAgentInstall
        {
            DestinationPath = "$($env:SystemDrive)\buildAgent"
            Recurse = $true
            SourcePath = 'D:\TeamCity\buildAgent'
            Type = 'Directory'
            MatchSource = $false
            DependsOn = '[Script]TeamCityExtract'
        }

        #include <AgentConfig>
    }
}