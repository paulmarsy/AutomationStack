param($Path, $InfraRg, $AutomationAccountName, $UDP, $OctopusAdminUsername, $OctopusAdminPassword, $ConnectionString, $HostHeader)

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $Path -Force -Published

$compilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'OctopusDeploy' -Parameters @{
    UDP = $UDP
    OctopusAdminUsername = $OctopusAdminUsername
    OctopusAdminPassword = $OctopusAdminPassword
    ConnectionString = $ConnectionString
    HostHeader = $HostHeader
}
while ($compilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
    Write-Host 'Waiting for compilation...'
    Start-Sleep -Seconds 10
    $compilationJob = $compilationJob | Get-AzureRmAutomationDscCompilationJob
}
$compilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any