function New-AutomationStack {
    param(
        [Parameter(DontShow)][int[]]$Stages
    )
    begin {
        if (!$Stages) {
            if ($null -eq $CurrentContext) {
                $Stages = 1..$TotalDeploymentStages
                $firstRun = $true
            } else {
                $currentStage = $CurrentContext.Get('CurrentStage')
                Write-Host -ForegroundColor Magenta "Resuming deployment from stage $currentStage"
                $Stages = $currentStage..$TotalDeploymentStages
                $firstRun = $false
            }  
        }
        if ($firstRun) {
            Install-AzureReqs -Basic
        }
        Connect-AzureRm
        if ($firstRun) {
            $azureRegion = Select-AzureLocation
            $computeVmShutdown = Select-ComputeVmAutoShutdown
        }     
    }
    process {
        try {
            $Stages | % {
                $stageNumber = $_
                if ($stageNumber -lt 1 -or $stageNumber -gt $TotalDeploymentStages) {
                    Write-Warning "Stage $stageNumber is outside the allowed range of 1-$TotalDeploymentStages, skipping"
                }
                $ScriptBlock = switch ($stageNumber) {
                    1 {
                        $Heading = 'Creating AutomationStack Deployment Context'
                        {
                            Install-AzureReqs

                            if ($null -eq $CurrentContext) {
                                New-DeploymentContext -AzureRegion $azureRegion -ComputeVmAutoShutdown $computeVmShutdown
                            } else {
                                Write-Warning 'AutomationStack deployment context already created, skipping'
                            }
                            
                            Show-AutomationStackDetail
                            Write-Host ('Azure Region: {0}' -f $CurrentContext.Get('AzureRegion'))
                            Start-Sleep -Seconds 2
                        }
                    }
                    2 {
                        $Heading = 'Azure KeyVault & Service Principal Authentication'
                        {
                            New-AzureServicePrincipal
                            Invoke-SharedScript Resources 'New-ResourceGroup' -UDP $CurrentContext.Get('UDP') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Location ($CurrentContext.Get('AzureRegion'))
                            Initialize-KeyVault
                            Connect-AzureRmServicePrincipal
                        }
                    }
                    3 {
                        $Heading = 'Provisioning Core Infrastructure'
                        {
                            Initialize-CoreInfrastructure
                        }
                    }
                    4 {
                        $Heading = 'Provisioning Octopus Deploy Infrastructure'
                        {
                            Register-OctopusAutomation
                        }
                    }
                    5 {
                        $Heading = 'Provisioning Octopus Deploy Application'
                        {
                            Initialize-OctopusDeployInfrastructure
                        }
                    }
                    6 {
                        $Heading = 'Uploading AutomationStack into Azure Storage'
                        {
                            Publish-StorageAccountResources -Upload All
                        }
                    }
                    7 {
                        $Heading = 'Azure Automation DSC Compliance'
                        {
                            Invoke-SharedScript Compute 'Invoke-CustomScript' -Name 'AutomationNodeCompliance' -ResourceGroupName $CurrentContext.Get('ResourceGroup') -VMName $CurrentContext.Get('OctopusVMName') -Location $CurrentContext.Get('AzureRegion') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
                        }
                    }     
                    8 {
                        $Heading = 'Octopus Deploy - Importing Initial State'
                        {
                            Invoke-SharedScript Compute 'Invoke-CustomScript' -Name 'OctopusImport' -ResourceGroupName $CurrentContext.Get('ResourceGroup') -VMName $CurrentContext.Get('OctopusVMName') -Location $CurrentContext.Get('AzureRegion') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
                        }
                    }
                    9 {
                        $Heading = 'Octopus Deploy - Publishing AutomationStack Packages'
                        {
                            Publish-OctopusNuGetPackages
                        }
                    }
                    10 {
                        $Heading = 'AutomationStack Deployment Complete'
                        {
                            Show-AutomationStackDetail
                            Write-Host -ForegroundColor Cyan "`t  Additional functionality can be deployed/enabled using Octopus Deploy"
                            Write-Host -ForegroundColor Green "`t   Octopus Deploy: $($CurrentContext.Get('OctopusHostHeader'))"
                            Open-AuthenticatedOctopusDeployUri
                            Write-Host
                            Write-Host -ForegroundColor Cyan "`t  TeamCity Server & TeamCity Agent Cloud, after deployed by Octopus, will be available at"
                            Write-Host -ForegroundColor Green "`t   TeamCity: $($CurrentContext.Eval('http://teamcitystack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com'))"
                            Write-Host
                            Write-Host -ForegroundColor Gray "`t  Available PowerShell Module commands:"
                            Write-Host -ForegroundColor Gray "`t`t- Measure-AutomationStack - Shows timing & deployment stats"
                            Write-Host -ForegroundColor Gray "`t`t- Show-AutomationStackUsage - Shows Azure usage & billing info (will take time for Azure to collate)"
                            Write-Host -ForegroundColor Gray "`t`t- Connect-AutomationStack <Octopus|TeamCity> - Opens RDP session to the relevant Azure VM"
                            Write-Host -ForegroundColor Gray "`t`t- Remove-AutomationStack - Removes Azure resources created by this deployment"
                            Write-Host -ForegroundColor Gray "`t`t- Find-AutomationStackDeployment - Searches for other AutomationStack deployments"                        }
                    }
                }
                Start-DeploymentStage -StageNumber $StageNumber -Heading $Heading -ScriptBlock $ScriptBlock
            }
        }
        finally {   
            Restore-AzureRmAuthContext
        }
    }
}