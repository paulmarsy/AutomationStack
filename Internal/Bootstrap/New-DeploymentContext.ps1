function New-DeploymentContext {
    param($AzureRegion)
    # X & Y - Not random
    # 1 - UDP, 2 Password start, 3 Password end        
    # 22222222-1111-Xxxx-Yxxx-333333333333
    $deploymentGuid1 = [guid]::NewGuid().guid
    # 4 - API Key, 5 - SQL Password
    # xxxxxxxx-4444-Xxxx-Yxxx-555555555555
    $deploymentGuid2 = [guid]::NewGuid().guid

    Write-Host 'Creating Octostache Config Store...'
    $script:CurrentContext = New-Object Octosprache $deploymentGuid1.Substring(9,4)
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
    $CurrentContext.Set('StackAdminPassword', ($deploymentGuid1.Substring(0,8) + (($deploymentGuid1.Substring(24,12).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join '')))  
    
    $sqlPassword = for ($i = 24; $i -lt $deploymentGuid2.Length; $i++) {
        if ($i % 2 -eq 0) { [char]::ToUpperInvariant($deploymentGuid2[$i]) }
        else { [char]::ToLowerInvariant($deploymentGuid2[$i]) }
    }
    $CurrentContext.Set('SqlServerPassword', ($sqlPassword -join ''))

    Add-Type -AssemblyName System.Web
    $CurrentContext.Set('ServicePrincipalClientSecret', [System.Web.Security.Membership]::GeneratePassword(16, 4))

    $CurrentContext.Set('ApiKey', ('API-AUTOMATIONstack{0}' -f $deploymentGuid2.Substring(9,4).ToUpperInvariant()))
}