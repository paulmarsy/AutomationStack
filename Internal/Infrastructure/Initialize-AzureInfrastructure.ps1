function Initialize-AzureInfrastructure {
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=#{SqlServerUsername};Password=#{SqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')

    Write-Host 'Configuring Storage Account...'
    Publish-AutomationStackResources -SkipAuth -Upload StackResources
    
    $global:configurationContent = [Newtonsoft.Json.JsonConvert]::SerializeObject((Invoke-DSCComposition -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1'))) | % Trim '"'
    $configurationDataFile = Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.psd1'
    if (Test-Path $configurationDataFile) {
        Write-Host "Loading DSC configuration file $configurationDataFile"
        $configurationData = Invoke-Expression (Get-Content $configurationDataFile -Raw)
    } else {
        $configurationData =  @{AllNodes = @()}
    }

    Start-ARMDeployment -Mode Uri -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'azuredeploy' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
        computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
        octopusDscJobId = [System.Guid]::NewGuid().ToString()
        octopusDscConfigurationContent = $configurationContent
        octopusDscConfigurationData = ($ConfigurationData | ConvertTo-Json -Compress).ToString()
        octopusDscVMName = $CurrentContext.Get('OctopusVMName')
        octopusDscConnectionString = $CurrentContext.Get('OctopusConnectionString')
        octopusDscOctopusHostName = $CurrentContext.Get('OctopusHostName')
        octopusDscOctopusVersionToInstall = 'latest' 
    } | Out-Null
}