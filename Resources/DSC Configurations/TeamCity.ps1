Configuration TeamCity
{
    param(
        $TentacleRegistrationUri,
        $TentacleRegistrationApiKey,
        $TeamCityHostHeader,
        $TeamCityVersion
    )
        
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
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

        $teamcityAgentConfigStateFile = "$($env:SystemDrive)\buildAgent\agentconfiguration.statefile"
        Script TeamCityAgentConfig
        {
            SetScript = {
                & "$($env:SystemDrive)\buildAgent\bin\changeAgentProps.bat" serverUrl $using:TeamCityHostHeader "$($env:SystemDrive)\buildAgent\conf\buildAgent.properties" *>&1 | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from TeamCity Agent Configuration: changeAgentProps serverUrl" }

                & "$($env:SystemDrive)\buildAgent\launcher\bin\TeamCityAgentService-windows-x86-32.exe" -i "$($env:SystemDrive)\buildAgent\launcher\conf\wrapper.conf" *>&1 | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from TeamCity Agent Configuration: TeamCityAgentService-windows-x86-64.exe" }

                $sc = Join-Path -Resolve ([System.Environment]::SystemDirectory) 'sc.exe'
                Write-Verbose "Found $netsh"

                & $sc config TCBuildAgent start= delayed-auto type= own *>&1 | Write-Verbose
                if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from TeamCity Agent Configuration: sc.exe" }

                [System.IO.FIle]::WriteAllText($using:teamcityAgentConfigStateFile, $LASTEXITCODE,[System.Text.Encoding]::ASCII)
            }
            TestScript = {
                ((Test-Path $using:teamcityAgentConfigStateFile) -and ([System.IO.FIle]::ReadAllText($using:teamcityAgentConfigStateFile).Trim()) -eq '0')
            }
            GetScript = { @{} }
            DependsOn = '[File]TeamCityAgentInstall'
        }
    }
}