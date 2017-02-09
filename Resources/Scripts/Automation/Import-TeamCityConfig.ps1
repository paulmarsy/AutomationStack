param($Path, $ResourceGroup, $AutomationAccountName, $TentacleRegistrationUri, $OctopusApiKey, $HostHeader, $TeamCityVersion)

& (Join-Path $PSScriptRoot 'Import-DSCConfiguration.ps1') -Path $Path -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    TentacleRegistrationUri = $TentacleRegistrationUri
    OctopusApiKey = $OctopusApiKey
    HostHeader = $HostHeader
    TeamCityVersion = $TeamCityVersion
}