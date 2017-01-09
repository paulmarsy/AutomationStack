while ($continueToPoll)
{
    Start-Sleep -Seconds 30
    $node = Get-AzureRmAutomationDscNode -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -Name $TeamCityVMName
    if ($node.Status -eq 'Compliant') {
        Write-Host "Node is compliant"
        $continueToPoll = $false
    }
    else {
        Write-Host "Node status is $($node.Status), waiting for compliance..."
    }
}