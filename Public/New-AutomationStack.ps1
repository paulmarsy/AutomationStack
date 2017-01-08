function New-AutomationStack {
    [CmdletBinding()]
    param(
        $Stages = 1..9
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
                        New-DeploymentContext
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
                    $Heading = 'Importing AutomationStack Optional Functionality'
                    {
                        Import-OctopusDeployInitialState
                    }
                }
                8 {
                    $ProgressText = 'Octopus Deploy - Resize VM' 
                    $Heading = 'Resizing Octopus Deploy VM'
                    {
                        $vm = Get-AzureRmVM  -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName')
                        $vm.HardwareProfile.VmSize = 'Standard_DS1_v2'
                        $vm | Update-AzureRmVM
                    }
                }
                9 {
                    $ProgressText = 'Complete' 
                    $Heading = 'AutomationStack Provisioning Complete'
                    {
                        Show-AutomationStackDetail -Octosprache $CurrentContext | Out-Null
                        $CurrentContext.Set('EndDateTime', (Get-Date))
                        Write-Host -ForegroundColor Magenta "`tAdditional functionality can be deployed/enabled using Octopus Deploy"
                        Write-Host
                        Write-Host -ForegroundColor Green 'Octopus Deploy Running at:' $CurrentContext.Get('OctopusHostHeader')
                        Write-Host
                        $duration = ([datetime]$CurrentContext.Get('EndDateTime')) - ([datetime]$CurrentContext.Get('StartDateTime'))
                        Write-Host "Total deployment time: $($duration.Minutes) minutes, $($duration.Seconds) seconds"
                        $CurrentContext.Set('DeploymentComplete', $true)
                    }
                }
            }

            Write-DeploymentUpdate -SequenceNumber $sequenceNumber -TotalStages 9 -ProgressText $ProgressText -Heading $Heading

            try {
                $ScriptBlock.Invoke()
            }
            catch {
                Write-Warning  $_.Exception.GetBaseException().ErrorRecord.Exception.Message
                Write-Warning 'Retrying stage...'
                Write-DeploymentUpdate -SequenceNumber $sequenceNumber -TotalStages 9 -ProgressText $ProgressText -Heading ('{0} (Attempt #2)' -f $Heading)
                $ScriptBlock.Invoke() 
            }
        }
        }
        finally {   
        $azureRmProfilePath = Join-Path $TempPath 'AzureRmProfile.json'
        if (Test-Path $azureRmProfilePath) {
            Write-Host -NoNewLine 'Restoring original Azure context...'
            Select-AzureRmProfile -Path $azureRmProfilePath | Out-Null
            Remove-Item -Path $azureRmProfilePath -Force
            Write-Host 'Restored'
        }
        }
    }
}