param($ResourceGroupName, $AutomationAccountName, $Name, $Parameters)

$automationJob = Start-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $Name -Parameters $Parameters
Write-Output "Azure Runbook $Name job created with id: $($automationJob.JobId)" 

$readOutput = @()
While ($status -notin @("Completed","Failed","Suspended","Stopped")) {
   $automationJob = Get-AzureRmAutomationJob -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $automationJob.JobId
   if ($status -ne $automationJob.Status) {
       $status = $automationJob.Status
       Write-Output "Azure Runbook $Name job is $status" 
   }
   if ($status -eq 'Running') {
        Get-AzureRmAutomationJobOutput -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $automationJob.JobId | ? StreamRecordId -notin $readOutput | % {
            $readOutput += $_.StreamRecordId
            $record = Get-AzureRmAutomationJobOutputRecord -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -JobId $automationJob.JobId -Id $_.StreamRecordId
            switch ($record.Type) {
                'Output' { $record.Value.Values | Write-Output }
                'Error' { Write-Error -Exception $record.Value.Exception -TargetObject $record.Value.TargetObject -ErrorId $record.Value.FullyQualifiedErrorId -CategoryActivity $record.Value.CategoryInfo.Activity -CategoryReason $record.Value.CategoryInfo.Reason -Category $record.Value.CategoryInfo.Category -CategoryTargetName $record.Value.CategoryInfo.TargetName -CategoryTargetType $record.Value.CategoryInfo.TargetType }
                'Warning' { Write-Warning -Message $record.Value.Message }
                'Verbose' { Write-Verbose -Message $record.Value.Message }
                'Progress' { Write-Progress -Activity $record.Value.Activity }
                default { Write-Output $record.Summary }
            }
        }
   }
    Start-Sleep -Milliseconds 250
}
if ($status -eq "Completed") { Write-Output "Runbook $Name completed successfully" }
else {
    Write-Warning "Runbook Job Exception:`n$($automationJob.Exception)"
    throw $automationJob.Exception
}