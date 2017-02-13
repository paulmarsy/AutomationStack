function New-DeploymentContext {
    param($AzureRegion, $ComputeVmAutoShutdown)

    Write-Host 'Creating Octostache Config Store...'
    $udp = Get-GuidPart 4
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

    Get-AzureRmContext | % Account | ? AccountType -eq 'User' | % Id | % { Get-AzureRmADUser -UserPrincipalName $_ -ErrorAction Ignore } | ? { $null -ne $_ } | % {
        $CurrentContext.Set('AzureUserObjectId', $_.Id.Guid)
    }

    $CurrentContext.Set('ComputeVmShutdownTask.Status', $ComputeVmAutoShutdown.Status)    
    $CurrentContext.Set('ComputeVmShutdownTask.Time', $ComputeVmAutoShutdown.Time)

    Write-Host 'Generating deployment passwords...'
    Add-Type -AssemblyName System.Web
    
    $CurrentContext.Set('StackAdminUsername', 'Stack')
    do {
        $CurrentContext.Set('StackAdminPassword', ((Get-GuidPart 8) + ((Get-GuidPart 4 -ToUpper))))
    } while  ($CurrentContext.Get('StackAdminPassword') -cnotmatch '^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$')

    $CurrentContext.Set('SqlServerName', 'azuresql-#{UDP}')
    $CurrentContext.Set('SqlServerUsername', '#{StackAdminUsername}')
    do {
        $CurrentContext.Set('SqlServerPassword', ((Get-GuidPart 12) + ((Get-GuidPart 8 -ToUpper))))
    } while  ($CurrentContext.Get('SqlServerPassword') -cnotmatch '^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{12,}$')
    $CurrentContext.Set('OctopusAutomationCredentialUsername', 'OctopusDeploy')
    $CurrentContext.Set('OctopusAutomationCredentialPassword', [System.Web.Security.Membership]::GeneratePassword(16, 4))
    $CurrentContext.Set('ServicePrincipalClientSecret', [System.Web.Security.Membership]::GeneratePassword(16, 4))
    $CurrentContext.Set('ApiKey', ('API-AUTOMATIONstack{0}{1}' -f (Get-GuidPart 4 -ToUpper), (Get-GuidPart 4)))

    $CurrentContext.Set('Username', '#{StackAdminUsername}')
    $CurrentContext.Set('Password', '#{StackAdminPassword}')

    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=#{SqlServerUsername};Password=#{SqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')

    $CurrentContext.Set('TeamCityHostName', 'teamcitystack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('TeamCityHostHeader', 'http://#{TeamCityHostName}/')
}