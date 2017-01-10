param($Path, $InfraRg, $AutomationAccountName, $UDP, $OctopusAdminUsername, $OctopusAdminPassword, $ConnectionString, $HostHeader)

Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $Path -Force -Published

$compilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'OctopusDeploy' -Parameters @{
    UDP = $UDP
    OctopusAdminUsername = $OctopusAdminUsername
    OctopusAdminPassword = $OctopusAdminPassword
    ConnectionString = $ConnectionString
    HostHeader = $HostHeader
}
while ($null -eq $compilationJob.EndTime -and $null -eq $CompilationJob.Exception)
{
    Write-Host 'Waiting for compilation...'
    Start-Sleep -Seconds 30
    $compilationJob = $compilationJob | Get-AzureRmAutomationDscCompilationJob
}
$compilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any