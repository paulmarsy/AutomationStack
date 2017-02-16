function Initialize-AzureInfrastructure {
    Write-Host 'Configuring Storage Account...'
    Publish-AutomationStackResources -SkipAuth -Upload StackResources
    
    $octopusDscConfiguration = Invoke-DSCComposition -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1')
    $octopusDscConfigurationData = Invoke-Expression (Get-Content -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.psd1') -Raw) | ConvertTo-Json -Compress

    $teamcityDscConfiguration = Invoke-DSCComposition -Path (Join-Path $ResourcesPath 'DSC Configurations\TeamCity.ps1')
    $teamcityDscConfigurationData = Invoke-Expression (Get-Content -Path (Join-Path $ResourcesPath 'DSC Configurations\TeamCity.psd1') -Raw) | ConvertTo-Json -Compress

    $CurrentContext.Set('OctopusCustomScriptLogFile', ('OctopusDeploy.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))))
    $CurrentContext.Set('TeamCityCustomScriptLogFile', ('TeamCity.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))))

    Start-ARMDeployment -Mode Uri -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'azuredeploy' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
        computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
        octopusDscJobId = [System.Guid]::NewGuid().ToString()
        octopusDscConfiguration = $octopusDscConfiguration
        octopusDscConfigurationData = $octopusDscConfigurationData
        octopusDscNodeName = $CurrentContext.Get('OctopusVMName')
        octopusDscConnectionString = $CurrentContext.Get('OctopusConnectionString')
        octopusDscHostName = $CurrentContext.Get('OctopusHostName')
        octopusCustomScriptLogFile = $CurrentContext.Get('OctopusCustomScriptLogFile')
        teamcityDscJobId = [System.Guid]::NewGuid().ToString()
        teamcityDscConfiguration = $teamcityDscConfiguration
        teamcityDscConfigurationData = $teamcityDscConfigurationData
        teamcityDscTentacleRegistrationUri = $CurrentContext.Get('OctopusHostHeader')
        teamcityDscTentacleRegistrationApiKey = $CurrentContext.Get('ApiKey')
        teamcityDscHostHeader = $CurrentContext.Get('TeamCityHostHeader')
        teamcityCustomScriptLogFile = $CurrentContext.Get('TeamCityCustomScriptLogFile')
    } | Out-Null
}