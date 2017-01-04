function Register-AutomationDSCNode {  
        param(
                $AzureVMName,
                $AzureVMResourceGroup,
                $Configuration,
                $Node,
                $Parameters
        )

        $CurrentContext.Set('AutomationAccountName', 'automation#{UDP}')

        Write-Host "Importing $Configuration DSC Configuration..."
        $NodeConfigurationFile = Join-Path -Resolve $ResourcesPath ('DSC Configurations\{0}.ps1' -f $Configuration) | Convert-Path
        Import-AzureRmAutomationDscConfiguration -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -SourcePath $NodeConfigurationFile -Force -Published

        $CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -ConfigurationName $Configuration -Parameters $Parameters
        while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
        {
                Write-Host 'Waiting for compilation...'
                Start-Sleep -Seconds 3
                $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
        }
        $CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any

        Write-Host "Registering $AzureVMName DSC Node..."
        Register-AzureRmAutomationDscNode -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -ResourceGroupName $CurrentContext.Get('InfraRg') -AzureVMName $AzureVMName -AzureVMResourceGroup $AzureVMResourceGroup -AzureVMLocation $CurrentContext.Get('AzureRegion') -NodeConfigurationName ('{0}.{1}' -f $Configuration, $Node) -ActionAfterReboot ContinueConfiguration -ConfigurationMode ApplyAndAutocorrect -ConfigurationModeFrequencyMins 15 -RefreshFrequencyMins 30 -RebootNodeIfNeeded $true -AllowModuleOverwrite $true

        $currentPollWait = 10
        $previousPollWait = 0
        $continueToPoll = $true
        $maxWaitSeconds = 60
        while ($continueToPoll)
        {
                Start-Sleep -Seconds ([System.Math]::Min($currentPollWait, $maxWaitSeconds))
                $node = Get-AzureRmAutomationDscNode -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Name $AzureVMName
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
}