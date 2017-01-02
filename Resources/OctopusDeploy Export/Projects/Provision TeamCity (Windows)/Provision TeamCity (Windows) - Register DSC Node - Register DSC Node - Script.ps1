Register-AzureRmAutomationDscNode -AutomationAccountName $AutomationAccountName -ResourceGroupName $InfraRg -AzureVMName $TeamCityVMName -AzureVMResourceGroup $TeamCityRg -AzureVMLocation $AzureRegion -NodeConfigurationName ('{0}.{1}' -f $DSCConfigurationName, $DSCNodeName) -ActionAfterReboot ContinueConfiguration -ConfigurationMode ApplyAndAutocorrect -ConfigurationModeFrequencyMins 15 -RefreshFrequencyMins 30 -RebootNodeIfNeeded $true -AllowModuleOverwrite $true

$currentPollWait = 10
$previousPollWait = 0
$continueToPoll = $true
$maxWaitSeconds = 60
while ($continueToPoll)
{
	Start-Sleep -Seconds ([System.Math]::Min($currentPollWait, $maxWaitSeconds))
        $node = Get-AzureRmAutomationDscNode -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -Name $TeamCityVMName
        if ($node.Status -eq 'Compliant') {
                Write-Host "Node is compliant"
                $continueToPoll = $false
        }
        else {
                Write-Host "Node status is $($node.Status), waiting for compliance..."
        }
	if ($currentPollWait -lt $maxWaitSeconds){
		$temp = $previousPollWait
		$previousPollWait = $currentPollWait
		$currentPollWait = $temp + $currentPollWait
	}
}