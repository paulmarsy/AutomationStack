param($Path, $InfraRg, $AutomationAccountName, $OctopusServerUrl, $OctopusApiKey, $OctopusEnvironment, $OctopusRole, $OctopusDisplayName)

$result = & (Join-Path $PSScriptRoot 'Invoke-DSCComposition.ps1') -Path $Path
$tempFile = Join-Path $env:TEMP (Split-Path $Path -Leaf)
Set-Content -Path $tempFile -Value $result

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $tempFile -Force -Published

Remove-Item -Path $tempFile -Force

$compilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    OctopusServerUrl = $OctopusServerUrl
    OctopusApiKey = $OctopusApiKey
    OctopusEnvironment = $OctopusEnvironment
    OctopusRole = $OctopusRole
    OctopusDisplayName = $OctopusDisplayName
}
while ($null -eq $compilationJob.EndTime -and $null -eq $CompilationJob.Exception)
{
    Write-Host 'Waiting for compilation...'
    Start-Sleep -Seconds 30
    $compilationJob = $compilationJob | Get-AzureRmAutomationDscCompilationJob
}
$compilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any