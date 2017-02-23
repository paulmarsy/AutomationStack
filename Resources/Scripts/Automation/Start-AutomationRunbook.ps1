param($ResourceGroupName, $AutomationAccountName, $Name, $Parameters)

$automationJob = Start-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $Name -Parameters $Parameters

$readOutput = @()
While ($status -notin @("Completed","Failed","Suspended","Stopped")) {
   $automationJobjob = Get-AzureRmAutomationJob -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $automationJob.JobId
   if ($status -ne $automationJob.Status) {
       $status = $automationJob.Status
       Write-Output "Azure Runbook $Name runbook is $status" 
   }
    Get-AzureRmAutomationJobOutput -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $automationJob.JobId | ? StreamRecordId -notin $readOutput | % {
        $readOutput += $_.StreamRecordId
        $record = Get-AzureRmAutomationJobOutputRecord -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -JobId $automationJob.JobId -Id $_.StreamRecordId
        switch ($record.Type) {
            'Output' { Write-Output $record.Value.Values }
            'Error' { Write-Error ($record.Value.Exception | Format-List * -Force | Out-String) }
            'Warning' { Write-Warning $record.Value.Message }
            'Verbose' { Write-Verbose $record.Value.Message }
            'Progress' { Write-Output $record.Value.Activity }
            default { Write-Output $record.Summary }
        }
        Write-Verbose $record.Summary
    }
   Start-Sleep -Seconds 1
}
if ($status -eq "Completed") { Write-Output "Runbook $Name completed successfully" }
else {
    Write-Warning "Runbook $Name did not complete successfully"
    throw "Runbook failed with status: $status"
}