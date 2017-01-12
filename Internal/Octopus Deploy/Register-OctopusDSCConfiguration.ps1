function Register-OctopusDSCConfiguration {
    Write-Host "Importing Octopus Deploy DSC Configuration..."
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=#{StackAdminUsername};Password=#{SqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')

    Invoke-SharedScript Automation 'Import-OctopusConfig' -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1') -InfraRg  $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -VMName $CurrentContext.Get('OctopusVMName') -ConnectionString $CurrentContext.Get('OctopusConnectionString') -HostHeader $CurrentContext.Get('OctopusHostHeader') -OctopusVersionToInstall 'latest'
}