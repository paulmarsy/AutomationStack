param($ResourceGroupName, $AutomationAccountName, [guid]$JobID)

$readOutput = @()
While ($status -notin @("Completed","Failed","Suspended","Stopped")) {
   $automationJob = Get-AzureRmAutomationJob -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $JobId
   if ($status -ne $automationJob.Status) {
       $status = $automationJob.Status
       Write-Output "Azure Automation Job changed to $status" 
   }
   if ($status -eq 'Running') {
        Get-AzureRmAutomationJobOutput -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Id $JobId | ? StreamRecordId -notin $readOutput | % {
            $readOutput += $_.StreamRecordId
            $record = Get-AzureRmAutomationJobOutputRecord -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -JobId $JobId -Id $_.StreamRecordId
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
if ($status -eq "Completed") { Write-Output "Azure Automation Job completed successfully" }
else {
    Write-Warning "Azure Automation Job Exception:`n$($automationJob.Exception)"
    throw $automationJob.Exception
}