& net use T: \\$StackResourcesName.file.core.windows.net\dsc /u:$StackResourcesName $StackResourcesKey
Import-AzureRmAutomationDscConfiguration -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -SourcePath $DSCConfigPath -Force -Published
& net use T: /DELETE

$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName $DSCConfigurationName -Parameters @{
    ApiKey = $APIKey
    OctopusServerUrl = $OctopusHostHeader
}

while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
        Write-Host 'Waiting for compilation...'
        Start-Sleep -Seconds 3
        $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
}

$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any