param($ResourceGroupName, $AutomationAccountName, $NodeName)

$continueToPoll = $true
while ($continueToPoll)
{
    Start-Sleep -Seconds 30
    $node = Get-AzureRmAutomationDscNode -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $NodeName
    if ($node.Status -eq 'Compliant') {
            Write-Host "Node is compliant"
            $continueToPoll = $false
    }
    else {
            Write-Host "Node status is $($node.Status), waiting for compliance..."
    }
}