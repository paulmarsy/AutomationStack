function New-AutomationStack {
    param(
        [Parameter(DontShow)][int[]]$Stages
    )
    begin {
        if (!$Stages) {
            if ($null -eq $CurrentContext) {
                $Stages = 1..$TotalDeploymentStages
            } else {
                $currentStage = $CurrentContext.Get('CurrentStage')
                Write-Host -ForegroundColor Magenta "Resuming deployment from stage $currentStage"
                $Stages = $currentStage..$TotalDeploymentStages
            }  
        }
        $firstRun = if ($null -eq $CurrentContext) {$true} else {$false}

        if ($firstRun) {
            Install-AzureModules
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
                            Install-AzureModules -All

                            if ($null -eq $CurrentContext) {
                                New-DeploymentContext -AzureRegion $azureRegion -ComputeVmAutoShutdown $computeVmShutdown
                            } else {
                                Write-Warning 'AutomationStack deployment context already created, skipping'
                            }
                            
                            Show-AutomationStackDetail
                            Write-Host ('Azure Region: {0}' -f $CurrentContext.Get('AzureRegion'))
                            Start-Sleep -Seconds 1
                        }
                    }
                    2 {
                        $Heading = 'Configuring Service Principal Authentication'
                        {
                            New-AzureServicePrincipal
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
                        $Heading = 'Provisioning Infrastructure'
                        {
                            $global:job = Add-AutomationStackFeature -Feature Infrastructure -DontJoin
                        }
                    }
                    5 {
                        $Heading = 'Uploading to Azure Storage'
                        {
                            Publish-AutomationStackResources -SkipAuth -Upload RunbookResources
                            Publish-AutomationStackResources -SkipAuth -Upload DataImports
                        }
                    }
                    6 {
                        $Heading = 'Provisioning Octopus Deploy'
                        {
                            $job.Join()
                            $global:job = Add-AutomationStackFeature -Feature OctopusDeploy -DontJoin
                            $job.Join()
                        }
                    }
                    7 {
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