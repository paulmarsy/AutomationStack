param($Path, $InfraRg, $AutomationAccountName, $OctopusServerUrl, $OctopusApiKey, $OctopusEnvironment, $OctopusRole, $OctopusDisplayName, $HostHeader, $TeamCityVersion)

$tempFile = & (Join-Path $PSScriptRoot 'Invoke-DSCComposition.ps1') -Path $Path

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $tempFile -Force -Published

Remove-Item -Path $tempFile -Force

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    OctopusServerUrl = $OctopusServerUrl
    OctopusApiKey = $OctopusApiKey
    OctopusEnvironment = $OctopusEnvironment
    OctopusRole = $OctopusRole
    OctopusDisplayName = $OctopusDisplayName
    HostHeader = $HostHeader
    TeamCityVersion = $TeamCityVersion
}