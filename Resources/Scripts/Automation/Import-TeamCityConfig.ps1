param($Path, $InfraRg, $AutomationAccountName, $OctopusServerUrl, $OctopusApiKey, $HostHeader, $TeamCityVersion)

$tempFile = & (Join-Path $PSScriptRoot 'Invoke-DSCComposition.ps1') -Path $Path

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $tempFile -Force -Published

Remove-Item -Path $tempFile -Force

$configurationDataFile = [System.IO.Path]::ChangeExtension($Path, 'psd1')
if (Test-Path $configurationDataFile) {
    $configurationData = Invoke-Expression (Get-Content $configurationDataFile -Raw)
} else {
    $configurationData =  @{AllNodes = @()}
}

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -ConfigurationData $configurationData -Parameters @{
    OctopusServerUrl = $OctopusServerUrl
    OctopusApiKey = $OctopusApiKey
    HostHeader = $HostHeader
    TeamCityVersion = $TeamCityVersion
}