param($Path, $ResourceGroupName, $AutomationAccountName, $ConfigurationName, $Parameters)

if (([System.IO.Path]::GetFileNameWithoutExtension($Path)) -ne $ConfigurationName) {
    throw "DSC Configuration filename must match the configuration name"
}

$tempFile = & (Join-Path $PSScriptRoot 'Invoke-DSCComposition.ps1') -Path $Path
Import-AzureRmAutomationDscConfiguration -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -SourcePath $tempFile -Force -Published -Tag (Get-AzureRmResourceGroup -Name $ResourceGroupName).Tags

$configurationDataFile = [System.IO.Path]::ChangeExtension($Path, 'psd1')
if (Test-Path $configurationDataFile) {
    Write-Host "Loading DSC configuration file $configurationDataFile"
    $configurationData = Invoke-Expression (Get-Content $configurationDataFile -Raw)
} else {
    $configurationData =  @{AllNodes = @()}
}

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ConfigurationName $ConfigurationName -ConfigurationData $configurationData -Parameters $Parameters