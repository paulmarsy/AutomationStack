function New-AutomationStack {
    [CmdletBinding()]
    param(
        [Parameter()][switch]$WhatIf,
        [Parameter(DontShow)]$TotalStages = 10,
        [Parameter(DontShow)]$Stages = (1..$TotalStages)
    )
    DynamicParam {
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        New-DynamicParam -Name AzureRegion -ValidateSet (Get-AzureLocations | % Name) -Position 0 -DPDictionary $Dictionary
    
        $Dictionary
    }
    begin{
        $AzureRegion = $PSBoundParameters.AzureRegion
        if (!$AzureRegion) {
            $AzureRegion = 'West Europe' # SQL Server isn't able to be provisioned in EUN currently
        }
        Install-AzurePowerShellModule
        Connect-AzureRm
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
                            New-DeploymentContext -AzureRegion $AzureRegion
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
                        $Heading = 'Publishing AutomationStack to Octopus Deploy Package Feed'
                        {
                            Send-ToOctopusPackageFeed (Join-Path -Resolve $ResourcesPath 'ARM Templates') 'ARMTemplates'
                            Send-ToOctopusPackageFeed $ScriptsPath 'AutomationStackScripts'
                        }
                    }
                    9 {
                        $ProgressText = 'Octopus Deploy - Resize VM' 
                        $Heading = 'Resizing Octopus Deploy VM'
                        {
                            $vm = Get-AzureRmVM  -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName')
                            $vm.HardwareProfile.VmSize = 'Standard_DS1_v2'
                            $vm | Update-AzureRmVM
                        }
                    }
                    10 {
                        $ProgressText = 'Complete' 
                        $Heading = 'AutomationStack Provisioning Complete'
                        {
                            $CurrentContext.TimingEnd('Deployment')
                            Show-AutomationStackDetail
                            Write-Host
                            Write-Host -ForegroundColor Magenta "`tAdditional functionality can be deployed/enabled using Octopus Deploy"
                            Write-Host
                            Write-Host -ForegroundColor Green "`tOctopus Deploy Running at: $($CurrentContext.Get('OctopusHostHeader'))"
                            Write-Host
                            Write-Host 'Timing & statistics of this deployment are available with the command: Measure-AutomationStackDeployment'
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