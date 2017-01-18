function Initialize-OctopusDeployInfrastructure {
    Write-Host 'Creating Octopus Deploy SQL Database...'
    Invoke-SharedScript AzureSQL 'New-AzureSQLDatabase' -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName 'OctopusDeploy'

    Write-Host
    Write-Host 'Deploying Octopus Deploy ARM Infrastructure...'
    $CurrentContext.Set('OctopusRg', 'OctopusStack#{UDP}')
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $octopusDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        infraResourceGroup = $CurrentContext.Get('InfraRg')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('StackAdminUsername')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
        registrationUrl = $CurrentContext.Get('AutomationRegistrationUrl')
        nodeConfigurationName = 'OctopusDeploy.Server'
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
    }

    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.enableencryption' -Mode Incremental -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $octopusDeploy.keyVaultSecretUrl.Value
    } | Out-Null
}
