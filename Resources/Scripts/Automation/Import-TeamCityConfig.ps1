param($Path, $InfraRg, $AutomationAccountName, $ApiKey, $OctopusServerUrl)

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $Path -Force -Published

$compilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'TeamCity' -Parameters @{
    ApiKey = $ApiKey
    OctopusServerUrl = $OctopusServerUrl
}
while ($compilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
    Write-Host 'Waiting for compilation...'
    Start-Sleep -Seconds 10
    $compilationJob = $compilationJob | Get-AzureRmAutomationDscCompilationJob
}
$compilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any