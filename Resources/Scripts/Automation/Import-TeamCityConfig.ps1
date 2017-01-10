param($Path, $InfraRg, $AutomationAccountName, $ApiKey, $OctopusServerUrl)

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $Path -Force -Published

$compilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    ApiKey = $ApiKey
    OctopusServerUrl = $OctopusServerUrl
}
while ($null -eq $compilationJob.EndTime -and $null -eq $CompilationJob.Exception)
{
    Write-Host 'Waiting for compilation...'
    Start-Sleep -Seconds 30
    $compilationJob = $compilationJob | Get-AzureRmAutomationDscCompilationJob
}
$compilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any