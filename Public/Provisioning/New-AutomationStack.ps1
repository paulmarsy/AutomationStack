function New-AutomationStack {
    param(
        [Parameter()][switch]$WhatIf,
        [Parameter(DontShow)][switch]$SkipChecks,
        [Parameter(DontShow)][int]$TotalStages = 9,
        [Parameter(DontShow)][int[]]$Stages = (1..$TotalStages)
    )
    DynamicParam {
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        New-DynamicParam -Name AzureRegion -ValidateSet (Get-AzureLocations | % Name) -Position 0 -DPDictionary $Dictionary
    
        $Dictionary
    }
    begin{
        $AzureRegion = $PSBoundParameters.AzureRegion
        if (!$AzureRegion) {
            $AzureRegion = 'West Europe'
        }
        if (!$SkipChecks) {
            Install-AzureReqs -Basic
            Connect-AzureRm
            Install-AzureReqs
        }
    }
    process{
        try {
            $Stages | % {
                $sequenceNumber = $_
                $ScriptBlock = switch ($sequenceNumber) {
                    1 {
                        $ProgressText = 'Deployment Context' 
                        $Heading = 'Creating AutomationStack Deployment Details'
                        {
                            if ($null -eq $CurrentContext) {
                                New-DeploymentContext -AzureRegion $AzureRegion
                            } else {
                                Write-Warning 'AutomationStack deployment details already created, skipping'
                            }
                            
                            Show-AutomationStackDetail
                        }
                    }
                    2 {
                        $ProgressText = 'Azure Service Principal & KeyVault' 
                        $Heading = 'Creating & Switching Authentication to Service Principal & KeyVault'
                        {
                            New-AzureServicePrincipal
                            Initialize-KeyVault
                            Connect-AzureRmServicePrincipal
                        }
                    }
                    3 {
                        $ProgressText = 'Core Infrastructure' 
                        $Heading = 'Provisioning Core Infrastructure'
                        {
                            Initialize-CoreInfrastructure
                        }
                    }
                    4 {
                        $ProgressText = 'Octopus Deploy - DSC Configuration'
                        $Heading = 'Compiling Octopus Deploy DSC Configuration'
                        {
                            Register-OctopusDSCConfiguration
                        }
                    }
                    5 {
                        $ProgressText = 'Octopus Deploy - Infrastructure'
                        $Heading = 'Provisioning Octopus Deploy'
                        {
                            Initialize-OctopusDeployInfrastructure
                        }
                    }
                    6 {
                        $ProgressText = 'AutomationStack Resources' 
                        $Heading = 'Uploading Resources to Azure Storage'
                        {
                            Publish-StackResources
                        }
                    }
                    7 {
                        $ProgressText = 'Octopus Deploy - Initial State' 
                        $Heading = 'Importing Octopus Deploy Initial State'
                        {
                            Import-OctopusDeployInitialState
                        }
                    }
                    8 {
                        $ProgressText = 'Octopus Deploy - AutomationStack Packages' 
                        $Heading = 'Publishing AutomationStack Scripts & Templates to Octopus Deploy'
                        {
                            Publish-StackPackages
                        }
                    }
                    9 {
                        $ProgressText = 'Complete' 
                        $Heading = 'AutomationStack Provisioning Complete'
                        {
                            $metrics = New-Object AutoMetrics $CurrentContext
                            $metrics.Finish('Deployment')
                            Show-AutomationStackDetail
                            Write-Host -ForegroundColor Cyan "`t  Additional functionality can be deployed/enabled using Octopus Deploy"
                            Write-Host
                            Write-Host -ForegroundColor Green "`t   Octopus Deploy URL (& copied to clipboard): $($CurrentContext.Get('OctopusHostHeader'))"
                            Set-Clipboard -Value $CurrentContext.Get('OctopusHostHeader')
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
                Start-DeploymentStage -SequenceNumber $SequenceNumber -TotalStages $TotalStages -ProgressText $ProgressText -Heading $Heading -ScriptBlock $ScriptBlock -WhatIf:$WhatIf
            }
        }
        finally {   
            Restore-AzureRmAuthContext
        }
    }
}