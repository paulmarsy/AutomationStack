function New-AutomationStack {
    [CmdletBinding()]
    param(
        $Stages = 1..10
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
    }
    process{
        try {
        $Stages | % {
            $sequenceNumber = $_
            $ScriptBlock = switch ($sequenceNumber) {
                1 {
                    $ProgressText = 'Prerequisites'
                    $Heading = 'installing prerequisites'
                    {
                        Install-AzurePowerShellModule
                    }
                }
                2 {
                    $ProgressText = 'Authenticating with Azure'
                    $Heading = 'Azure Authentication'
                    {
                        Connect-AzureRm
                        Set-AzureSubscriptionSelection
                    }
                }
                3 {
                    $ProgressText = 'Deployment Context' 
                    $Heading = 'Creating AutomationStack Deployment Details'
                    {
                        New-DeploymentContext
                    }
                }
                4 {
                    $ProgressText = 'Azure Service Principal & KeyVault' 
                    $Heading = 'Creating & Switching Authentication to Service Principal & KeyVault'
                    {
                        New-AzureServicePrincipal
                        Initialize-KeyVault
                        Connect-AzureRmServicePrincipal
                    }
                }
                5 {
                    $ProgressText = 'Core Infrastructure' 
                    $Heading = 'Provisioning Core Infrastructure'
                    {
                        Initialize-CoreInfrastructure
                    }
                }
                6 {
                    $ProgressText = 'Octopus Deploy - DSC Configuration'
                    $Heading = 'Compiling Octopus Deploy DSC Configuration'
                    {
                        Register-OctopusDSCConfiguration
                    }
                }
                7 {
                    $ProgressText = 'Octopus Deploy - Infrastructure'
                    $Heading = 'Provisioning Octopus Deploy'
                    {
                        Initialize-OctopusDeployInfrastructure
                    }
                }
                8 {
                    $ProgressText = 'AutomationStack Resources' 
                    $Heading = 'Uploading Resources to Azure Storage'
                    {
                        Publish-StackResources
                    }
                }
                9 {
                    $ProgressText = 'Octopus Deploy - Initial State' 
                    $Heading = 'Importing AutomationStack Optional Functionality'
                    {
                        Import-OctopusDeployInitialState
                    }
                }
                10 {
                    $ProgressText = 'Complete' 
                    $Heading = 'AutomationStack Provisioning Complete'
                    {
                        Show-AutomationStackDetail -Octosprache $CurrentContext | Out-Null
                        Write-Host -ForegroundColor Magenta "`tAdditional functionality can be deployed/enabled using Octopus Deploy"
                        Write-Host
                        Write-Host -ForegroundColor Green 'Octopus Deploy Running at:' $CurrentContext.Get('OctopusHostHeader')
                        $CurrentContext.Set('DeploymentComplete', $true)
                    }
                }
            }

            Write-DeploymentUpdate -SequenceNumber $sequenceNumber -TotalStages 10 -ProgressText $ProgressText -Heading $Heading

            try {
                $ScriptBlock.Invoke()
              #  throw 'test retry on all stages'
            }
            catch {
                Write-Warning $_.Exception.Message
                Write-Warning 'Retrying stage...'
                Write-DeploymentUpdate -SequenceNumber $sequenceNumber -TotalStages 10 -ProgressText $ProgressText -Heading ('{0} (Attempt #2)' -f $Heading)
                $ScriptBlock.Invoke() 
            }
        }
        }
        finally {   
        $azureRmProfilePath = Join-Path $TempPath 'AzureRmProfile.json'
        if (Test-Path $azureRmProfilePath) {
            Write-Host -NoNewLine 'Restoring original Azure context...'
            Select-AzureRmProfile -Path $azureRmProfilePath
            Remove-Item -Path $azureRmProfilePath -Force
            Write-Host 'Restored'
        }
        }
    }
}