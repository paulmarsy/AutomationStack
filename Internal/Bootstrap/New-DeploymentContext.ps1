function New-DeploymentContext {
    param($AzureRegion)
    # X & Y - Not random
    # 1 - UDP, 2 Password start, 3 Password end  , 4 - Api key      
    # 22222222-1111-X444-Y444-333333333333
    $deploymentGuid = [guid]::NewGuid().guid

    Write-Host 'Creating Octostache Config Store...'
    $script:CurrentContext = New-Object Octosprache $deploymentGuid.Substring(9,4)
    $CurrentContext.TimingStart('Deployment')
    $CurrentContext.TimingStart(1)
    $CurrentContext.Set('Name', 'AutomationStack#{UDP}')
    
    $azureRmContext = Get-AzureRmContext
    $CurrentContext.Set('AzureTenantId', $azureRmContext.Tenant.TenantId)
    $CurrentContext.Set('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)
    $CurrentContext.Set('AzureRegion', $AzureRegion)
    $CurrentContext.Set('AzureRegionValue', (Get-AzureLocations | ? Name -eq $AzureRegion | % Value))
    $CurrentContext.Set('InfraRg', 'AutomationStack#{UDP}')

    Write-Host 'Generating deployment passwords...'
    $CurrentContext.Set('StackAdminUsername', 'Stack')
    $CurrentContext.Set('StackAdminPassword', ($deploymentGuid.Substring(0,8) + (($deploymentGuid.Substring(24,12).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join '')))  
    
    $CurrentContext.Set('SqlServerPassword', (New-ContextSafePassword))

    Add-Type -AssemblyName System.Web
    $CurrentContext.Set('ServicePrincipalClientSecret', [System.Web.Security.Membership]::GeneratePassword(16, 4))

    $CurrentContext.Set('ApiKey', ('API-AUTOMATIONstack{0}{1}' -f $deploymentGuid.Substring(15,3).ToUpperInvariant(), $deploymentGuid.Substring(20,3).ToUpperInvariant()))
}