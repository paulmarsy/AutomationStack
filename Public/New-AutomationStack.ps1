function New-AutomationStack {
    param(
        [Parameter(Mandatory=$true)]$AzureRegion = 'West Europe' #'North Europe' - SQL Server isn't able to be provisioned in EUN currently
    )
    
    $deploymentGuid = [guid]::NewGuid().guid
    Write-Host "Deployment Guid: $deploymentGuid"
    
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Authenticating with Azure' -PercentComplete (1/7*100) 
    Connect-AzureRm
    Set-AzureSubscriptionSelection

    $automationStackDetail = Show-AutomationStackDetail -Guid $deploymentGuid -AzureRegion $AzureRegion -PassThru

    Write-Host 'Creating Octostache Config Store...'
    $script:CurrentContext  = Get-OctospracheState -UDP $automationStackDetail.UDP
    $CurrentContext.Set('Username', $automationStackDetail.Username)
    $CurrentContext.Set('Password', $automationStackDetail.Password)    
    $CurrentContext.Set('Name', 'AutomationStack#{UDP}')

    $azureRmContext = Get-AzureRmContext
    $CurrentContext.Set('AzureTenantId', $azureRmContext.Tenant.TenantId)
    $CurrentContext.Set('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)
    $CurrentContext.Set('AzureRegion', $automationStackDetail.AzureRegion)
    
    <# Deployment starts here #>
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Creating Azure Service Principal' -PercentComplete (2/7*100) 
    New-AzureServicePrincipal
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Provisioning Core Infrastructure' -PercentComplete (3/7*100) 
    Initialize-CoreInfrastructure
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Provisioning Octopus Deploy' -PercentComplete (4/7*100) 
    Initialize-OctopusDeployInfrastructure
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Uploading AutomationStack Resources' -PercentComplete (5/7*100) 
    Publish-StackResources
    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Configuring Octopus Deploy' -PercentComplete (6/7*100) 
    Resume-OctopusDeployConfiguration

    Write-Progress -Activity 'AutomationStack Deployment' -Status 'Done' -PercentComplete (7/7*100) 
    Show-AutomationStackDetail -Octosprache $CurrentContext
    Write-Host -ForegroundColor Green 'Octopus Deploy Running at:' $context.Get('OctopusHostHeader')
    $CurrentContext.Set('DeploymentComplete', $true)
}