function Initialize-OctopusDeployInfrastructure {
    Write-Host
    Write-Host 'Deploying Octopus Deploy ARM Infrastructure...'
    $CurrentContext.Set('OctopusRg', 'OctopusStack#{UDP | ToUpper}')
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

    $CurrentContext.Set('OctopusDiskEncryptionKeyUrl', $octopusDeploy.keyVaultSecretUrl.Value)

    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.enableencryption' -Mode Incremental -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $CurrentContext.Get('OctopusDiskEncryptionKeyUrl')
    } | Out-Null
}
