function New-AutomationStack {
    param(
        [Parameter(Mandatory=$false)]$AzureRegion = 'West Europe', #'North Europe' - SQL Server isn't able to be provisioned in EUN currently
        $Stage = 1
    )
   
    while ($Stage -le 8) {
        switch ($Stage) {
            1 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Authenticating with Azure' -PercentComplete (1/9*100) 
                Connect-AzureRm
                Set-AzureSubscriptionSelection
            }
            2 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Creating Deployment Context' -PercentComplete (2/9*100) 
                New-DeploymentContext
            }
            3 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Creating Azure Service Principal' -PercentComplete (3/9*100) 
                New-AzureServicePrincipal
            }
            4 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Provisioning Core Infrastructure' -PercentComplete (4/9*100) 
                Initialize-CoreInfrastructure
            }
            5 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Provisioning Octopus Deploy' -PercentComplete (5/9*100) 
                Initialize-OctopusDeployInfrastructure
            }
            6 {
                Write-Progress -Activity 'AutomationStack Deployment' -Status 'Uploading AutomationStack Resources' -PercentComplete (6/9*100) 
                Publish-StackResources
            }
            7 {
               Write-Progress -Activity 'AutomationStack Deployment' -Status 'Configuring Octopus Deploy' -PercentComplete (7/9*100) 
               Resume-OctopusDeployConfiguration
            }
            8 {
               Write-Progress -Activity 'AutomationStack Deployment' -Status 'Importing Octopus Deploy Initial State' -PercentComplete (8/9*100) 
               Import-OctopusDeployInitialState
            }
        }
        $Stage++
    }

    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Done' -PercentComplete (9/9*100) 
    Show-AutomationStackDetail -Octosprache $CurrentContext
    Write-Host -ForegroundColor Green 'Octopus Deploy Running at:' $CurrentContext.Get('OctopusHostHeader')
    $CurrentContext.Set('DeploymentComplete', $true)
}