function Initialize-AzureInfrastructure {
    Write-Host "Importing Octopus Deploy DSC Configuration..."
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=#{SqlServerUsername};Password=#{SqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')
    Invoke-SharedScript Automation 'Import-OctopusConfig' -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1') -ResourceGroup  $CurrentContext.Get('ResourceGroup') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') `
        -VMName $CurrentContext.Get('OctopusVMName') `
        -ConnectionString $CurrentContext.Get('OctopusConnectionString') `
        -OctopusHostName $CurrentContext.Get('OctopusHostName') `
        -OctopusVersionToInstall 'latest' | Out-Host
        
    Write-Host 'Configuring Storage Account...'
    Publish-AutomationStackResources -SkipAuth -Upload StackResources

    Start-ARMDeployment -Mode Uri -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'azuredeploy' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
        computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
    } | Out-Null
}