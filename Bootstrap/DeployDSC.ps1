        
param(
    [Parameter(Mandatory=$true)]$UDP,
    $AzureVMName,
    $AzureVMResourceGroup,
    $AzureVMLocation,
    $Configuration,
    $Node,
    $Parameters
)

$rg = 'AutomationStack{0}' -f $UDP
$aa = 'automation{0}' -f $UDP

Write-Host "Importing $Configuration DSC Configuration..."
$NodeConfigurationFile = Join-Path -Resolve $PSScriptRoot ('..\Resources\DSC Configurations\{0}.ps1' -f $Configuration) | Convert-Path
Import-AzureRmAutomationDscConfiguration -ResourceGroupName $rg -AutomationAccountName $aa -SourcePath $NodeConfigurationFile -Force -Published

$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $rg -AutomationAccountName $aa -ConfigurationName $Configuration -Parameters $Parameters

while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
        Write-Host 'Waiting for compilation...'
        Start-Sleep -Seconds 5
        $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
}

$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any

Write-Host "Registering $AzureVMName DSC Node..."
Register-AzureRmAutomationDscNode -AutomationAccountName $aa -ResourceGroupName $rg -AzureVMName $AzureVMName -AzureVMResourceGroup $AzureVMResourceGroup -AzureVMLocation $AzureVMLocation -NodeConfigurationName ('{0}.{1}' -f $Configuration, $Node) -ActionAfterReboot ContinueConfiguration -ConfigurationMode ApplyAndAutocorrect -ConfigurationModeFrequencyMins 15 -RefreshFrequencyMins 30 -RebootNodeIfNeeded $true -AllowModuleOverwrite $true

$node = Get-AzureRmAutomationDscNode -ResourceGroupName $rg -AutomationAccountName $aa -Name $AzureVMName
while ($node.Status -ne 'Compliant')
{            
        Write-Host "Node is $($node.Status), waiting for compliance..."
        Start-Sleep -Seconds 5
        $node = Get-AzureRmAutomationDscNode -ResourceGroupName $rg -AutomationAccountName $aa -Name $AzureVMName
}
