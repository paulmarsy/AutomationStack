param($Path, $InfraRg, $AutomationAccountName, $OctopusServerUrl, $OctopusApiKey, $OctopusEnvironment, $OctopusRole, $OctopusDisplayName)

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $Path -Force -Published

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