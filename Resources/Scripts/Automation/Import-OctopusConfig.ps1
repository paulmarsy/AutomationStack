param($Path, $InfraRg, $AutomationAccountName, $VMName, $ConnectionString, $HostHeader, $OctopusVersionToInstall)

$tempFile = & (Join-Path $PSScriptRoot 'Invoke-DSCComposition.ps1') -Path $Path

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $tempFile -Force -Published

Remove-Item -Path $tempFile -Force

$configurationDataFile = [System.IO.Path]::ChangeExtension($Path, 'psd1')
if (Test-Path $configurationDataFile) {
    $configurationData = Invoke-Expression (Get-Content $configurationDataFile -Raw)
} else {
    $configurationData =  @{AllNodes = @()}
}

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'OctopusDeploy' -ConfigurationData $configurationData -Parameters @{
    OctopusNodeName = $VMName
    ConnectionString = $ConnectionString
    HostHeader = $HostHeader
    OctopusVersionToInstall = $OctopusVersionToInstall
}