function New-DeploymentContext {
    param($AzureRegion)

    # X & Y - Not random
    # 1 - UDP, 2 Password start, 3 Password end  , 4 - Api key      
    # 22222222-1111-X444-Y444-333333333333
    $deploymentGuid = [guid]::NewGuid().guid

    Write-Host 'Creating Octostache Config Store...'
    $udp = $deploymentGuid.Substring(9,4)
    $script:CurrentContext = New-Object Octosprache $udp
    $CurrentContext.Set('UDP', $udp)

    [AutoMetrics]::Start(1, 'Creating AutomationStack Deployment Details')
    $CurrentContext.Set('Name', 'AutomationStack#{UDP | ToUpper}')
    $CurrentContext.Set('ResourceGroup', 'AutomationStack#{UDP | ToUpper}')

    $azureRmContext = Get-AzureRmContext
    $CurrentContext.Set('AzureTenantId', $azureRmContext.Tenant.TenantId)
    $CurrentContext.Set('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)

    $CurrentContext.Set('AzureRegion', $AzureRegion.Name)
    $CurrentContext.Set('AzureRegionValue', $AzureRegion.Value)
    
    Write-Host 'Creating Azure Tags...'
    New-AzureRmTag -Name application -Value AutomationStack
    New-AzureRmTag -Name udp -Value $udp

    Write-Host 'Generating deployment passwords...'
    Add-Type -AssemblyName System.Web
    
    $CurrentContext.Set('StackAdminUsername', 'Stack')
    $CurrentContext.Set('StackAdminPassword', ($deploymentGuid.Substring(0,8) + (($deploymentGuid.Substring(24,12).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join '')))
    $CurrentContext.Set('SqlServerUsername', '#{StackAdminUsername}')
    $CurrentContext.Set('SqlServerPassword', (New-ContextSafePassword))
    $CurrentContext.Set('OctopusAutomationCredentialUsername', 'OctopusDeploy')
    $CurrentContext.Set('OctopusAutomationCredentialPassword', [System.Web.Security.Membership]::GeneratePassword(16, 4))
    $CurrentContext.Set('ServicePrincipalClientSecret', [System.Web.Security.Membership]::GeneratePassword(16, 4))
    $CurrentContext.Set('ApiKey', ('API-AUTOMATIONstack{0}{1}' -f $deploymentGuid.Substring(15,3).ToUpperInvariant(), $deploymentGuid.Substring(20,3).ToUpperInvariant()))

    $CurrentContext.Set('Username', '#{StackAdminUsername}')
    $CurrentContext.Set('Password', '#{StackAdminPassword}')
}