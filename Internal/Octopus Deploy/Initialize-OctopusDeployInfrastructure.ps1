function Initialize-OctopusDeployInfrastructure {
    Write-Host
    Write-Host 'Deploying Octopus Deploy ARM Infrastructure...'
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $octopusDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'appserver' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('StackAdminUsername')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
        registrationUrl = $CurrentContext.Get('AutomationRegistrationUrl')
        nodeConfigurationName = 'OctopusDeploy.Server'
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
        computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
    }

    $CurrentContext.Set('OctopusDiskEncryptionKeyUrl', $octopusDeploy.keyVaultSecretUrl.Value)

    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'appserver.enableencryption' -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $CurrentContext.Get('OctopusDiskEncryptionKeyUrl')
    } | Out-Null
}
