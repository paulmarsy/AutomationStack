function New-DeploymentContext {
    $deploymentGuid = [guid]::NewGuid().guid
    Write-Host "Deployment Guid: $deploymentGuid"
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
    $CurrentContext.Set('InfraRg', 'AutomationStack#{UDP}')
}