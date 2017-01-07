$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName $DSCConfigurationName -Parameters @{
    UDP = $UDP
    OctopusAdminUsername = $StackAdminUsername
    OctopusAdminPassword = $StackAdminPassword
    ConnectionString = $OctopusConnectionString
    HostHeader = $OctopusHostHeader
    OctopusVersion = $OctopusParameters['Octopus.Release.Number']
}

while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
        Write-Host 'Waiting for compilation...'
        Start-Sleep -Seconds 10
        $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
}

$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any