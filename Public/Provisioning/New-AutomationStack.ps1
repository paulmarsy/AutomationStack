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
        }     
    }
    process {
        try {
            $Stages | % {
                $stageNumber = $_
                if ($stageNumber -lt 1 -or $stageNumber -gt $TotalDeploymentStages) {
                    Write-Warning "Stage $stageNumber is outside the allowed range of 0-$TotalDeploymentStages, skipping"
                }
                $CurrentContext.Set('CurrentStage', $StageNumber)
                $ScriptBlock = switch ($stageNumber) {
                    1 {
                        $Heading = 'Creating AutomationStack Deployment Context'
                        {
                            Install-AzureReqs

                            if ($null -eq $CurrentContext) {
                                New-DeploymentContext -AzureRegion $azureRegion
                            } else {
                                Write-Warning 'AutomationStack deployment context already created, skipping'
                            }
                            
                            Show-AutomationStackDetail
                        }
                    }
                    2 {
                        $Heading = 'Azure KeyVault & Service Principal Authentication'
                        {
                            New-AzureServicePrincipal
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
                            Write-Host 'Creating Octopus Deploy SQL Database...'
                            Invoke-SharedScript AzureSQL 'New-AzureSQLDatabase' -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName 'OctopusDeploy'
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
                            Invoke-SharedScript Compute 'Invoke-CustomScript' -Name 'AutomationNodeCompliance' -ResourceGroupName $CurrentContext.Get('OctopusRg') -VMName $CurrentContext.Get('OctopusVMName') -Location $CurrentContext.Get('AzureRegion') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
                        }
                    }     
                    8 {
                        $Heading = 'Octopus Deploy - Importing Initial State'
                        {
                            Invoke-SharedScript Compute 'Invoke-CustomScript' -Name 'OctopusImport' -ResourceGroupName $CurrentContext.Get('OctopusRg') -VMName $CurrentContext.Get('OctopusVMName') -Location $CurrentContext.Get('AzureRegion') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
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
                            $metrics = New-Object AutoMetrics $CurrentContext
                            $metrics.Finish('Deployment')
                            Show-AutomationStackDetail
                            Write-Host -ForegroundColor Cyan "`t  Additional functionality can be deployed/enabled using Octopus Deploy"
                            Write-Host
                            Write-Host -ForegroundColor Green "`t   Octopus Deploy URL (& copied to clipboard): $($CurrentContext.Get('OctopusHostHeader'))"
                            Microsoft.PowerShell.Management\Set-Clipboard -Value $CurrentContext.Get('OctopusHostHeader')
                            Write-Host
                            Write-Host -ForegroundColor Gray "`t  Available PowerShell Module commands:"
                            Write-Host -ForegroundColor Gray "`t`t- Measure-AutomationStack - Shows timing & deployment stats"
                            Write-Host -ForegroundColor Gray "`t`t- Connect-AutomationStack <Octopus|TeamCity> - Opens RDP session with the Azure VM (NSG RDP Rule must be enabled"
                            Write-Host -ForegroundColor Gray "`t`t- Remove-AutomationStack - Removes Azure resources created by the project including the Service Principal"
                            Write-Host -ForegroundColor Gray "`t`t- New-AutomationStack - Creates another isolated & seperate instance of AutomationStack"
                            Write-Host -ForegroundColor Gray "`t`t- Import-Module AutomationStack -ArgumentList <UDP> - Imports the module with the context of a previous deployment"
                            $CurrentContext.Set('DeploymentComplete', $true)
                        }
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