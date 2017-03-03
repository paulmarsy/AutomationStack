param($ResourceGroupName, $AutomationAccountName, $Name, $Parameters)

$automationJob = Start-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $Name -Parameters $Parameters
Write-Output "Azure Runbook $Name job created with id: $($automationJob.JobId)" 

return $automationJob.JobId