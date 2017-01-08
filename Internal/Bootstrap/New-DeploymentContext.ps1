function New-DeploymentContext {
    $deploymentGuid = [guid]::NewGuid().guid
    Write-Host "Deployment Guid: $deploymentGuid"
    $automationStackDetail = Show-AutomationStackDetail -Guid $deploymentGuid -AzureRegion $AzureRegion

    Write-Host 'Creating Octostache Config Store...'
    $script:CurrentContext = [octosprache]::new($automationStackDetail.UDP)
    $CurrentContext.Set('StartDateTime', (Get-Date))
    $CurrentContext.Set('Username', $automationStackDetail.Username)
    $CurrentContext.Set('Password', $automationStackDetail.Password)    
    $CurrentContext.Set('Name', 'AutomationStack#{UDP}')
    
    $azureRmContext = Get-AzureRmContext
    $CurrentContext.Set('AzureTenantId', $azureRmContext.Tenant.TenantId)
    $CurrentContext.Set('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)
    $CurrentContext.Set('AzureRegion', $automationStackDetail.AzureRegion)
    $CurrentContext.Set('AzureRegionValue', $automationStackDetail.AzureRegionValue)
    $CurrentContext.Set('InfraRg', 'AutomationStack#{UDP}')
}