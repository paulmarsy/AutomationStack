Configuration TeamCity
{
    param(
        $ApiKey,
        $OctopusServerUrl
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName cChoco
    
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
         cChocoInstaller InstallChocolatey
        { 
            InstallDir = "C:\Chocolatey" 
        }
        cChocoPackageInstaller JRE 
        {            
            Name = "server-jre8" 
            DependsOn = "[cChocoInstaller]InstallChocolatey"
        } 
        cChocoPackageInstaller TeamCity 
        {            
            Name = "teamcity" 
            DependsOn = "[cChocoPackageInstaller]JRE"
        } 
        Environment TeamCityDataDir
        {
            Ensure = "Present" 
            Name = "TEAMCITY_DATA_PATH"
            Value = "${env:ALLUSERSPROFILE}\JetBrains\TeamCity"
        }
    }
}