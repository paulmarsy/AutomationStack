Configuration OctopusDeploy
{
    param(
        $UDP,
        $OctopusAdminUsername,
        $OctopusAdminPassword,
        $ConnectionString,
        $HostHeader
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName OctopusDSC
    Import-DscResource -ModuleName xNetworking

    Node "Server"
    {
        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"
            Name = "OctopusServer"
            WebListenPrefix = $HostHeader
            SqlDbConnectionString = $ConnectionString
            OctopusAdminUsername = $OctopusAdminUsername
            OctopusAdminPassword = $OctopusAdminPassword
            AllowUpgradeCheck = $true
            AllowCollectionOfAnonymousUsageStatistics = $false
            ForceSSL = $false
            ListenPort = 10943
            DownloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"
        }
        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            DependsOn = '[cOctopusServer]OctopusServer'
        }
        Script 'Octopus License'
        {
            SetScript = {
              $postParams = @{ 
                  FullName=$env:USERNAME
                  Organization=$env:USERDOMAIN
                  EmailAddress="${env:USERNAME}@${env:USERDOMAIN}.com"
                  Source="azure"
                 }
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://octopusdeploy.com/api/licenses/trial" -Method POST -Body $postParams
                $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
                $bytes  = $utf8NoBOM.GetBytes($response.Content)
                $licenseBase64 = [System.Convert]::ToBase64String($bytes)
                $args = @(
                    'license', 
                    '--console',
                    '--instance', 'OctopusServer', 
                    '--licenseBase64', $licenseBase64
                )
                & 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe' $args
                [System.IO.FIle]::WriteAllText("$($env:SystemDrive)\Octopus\Octopus.Server.DSC.licensestate", $LASTEXITCODE,[System.Text.Encoding]::ASCII)

            }
            TestScript = {
                ((Test-Path "$($env:SystemDrive)\Octopus\Octopus.Server.DSC.licensestate") -and ([System.IO.FIle]::ReadAllText("$($env:SystemDrive)\Octopus\Octopus.Server.DSC.licensestate").Trim()) -eq '0')
            }
            GetScript = { }
            DependsOn = '[cOctopusServer]OctopusServer'
        }
        xFirewall Firewall
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

    #    Invoke-WebRequest -UseBasicParsing -Uri ('{0}/api/users/authenticate/usernamepassword' -f $HostHeader) -Method Post -Body (@{Username = $OctopusAdminUsername; Password = $OctopusAdminPassword; RememberMe = $false }| ConvertTo-Json) -SessionVariable octopusSession | Out-Null		
     #   $myOctopusUserId = Invoke-WebRequest -UseBasicParsing -Uri ('{0}/api/users/me' -f $HostHeader) -WebSession $octopusSession | % Content | ConvertFrom-Json | % Id		
      #  $apiKey = Invoke-WebRequest -UseBasicParsing -Uri ('{0}/api/users/{1}/apikeys' -f $HostHeader, $myOctopusUserId) -WebSession $octopusSession -Method Post -Body (@{Purpose='AutomationStack'} | ConvertTo-Json) | % Content | ConvertFrom-Json | % ApiKey		
       # Write-Verbose "Octopus API Key: $apiKey" 
    }
}