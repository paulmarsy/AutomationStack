function Register-OctopusDSCConfiguration {
    Write-Host "Importing Octopus Deploy DSC Configuration..."
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=#{Username};Password=#{Password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')

    $NodeConfigurationFile = Join-Path -Resolve $ResourcesPath ('DSC Configurations\OctopusDeploy.ps1' -f $Configuration) | Convert-Path
    Import-AzureRmAutomationDscConfiguration -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -SourcePath $NodeConfigurationFile -Force -Published

    $CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -ConfigurationName 'OctopusDeploy' -Parameters @{
        UDP = $CurrentContext.Get('UDP')
        OctopusAdminUsername = $CurrentContext.Get('Username')
        OctopusAdminPassword = $CurrentContext.Get('Password')
        ConnectionString = $CurrentContext.Get('OctopusConnectionString')
        HostHeader = $CurrentContext.Get('OctopusHostHeader')
    }
    while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
    {
        Write-Host 'Waiting for compilation...'
        Start-Sleep -Seconds 10
        $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
    }
    $CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any
}