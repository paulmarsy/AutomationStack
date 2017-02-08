param($Path, $ResourceGroup, $AutomationAccountName, $OctopusServerUrl, $OctopusApiKey, $HostHeader, $TeamCityVersion)

& (Join-Path $PSScriptRoot 'Import-DSCConfiguration.ps1') -Path $Path -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    OctopusServerUrl = $OctopusServerUrl
    OctopusApiKey = $OctopusApiKey
    HostHeader = $HostHeader
    TeamCityVersion = $TeamCityVersion
}