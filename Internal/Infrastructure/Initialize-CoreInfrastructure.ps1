function Initialize-CoreInfrastructure {
    Invoke-SharedScript Resources 'New-ResourceGroup' -UDP $CurrentContext.Get('UDP') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Location ($CurrentContext.Get('AzureRegion'))

    $CurrentContext.Set('KeyVaultName', 'keyvault-#{UDP}')
    $coreInfrastructureDeploy = Start-ARMDeployment -Mode File -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'coreinfrastructure' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        servicePrincipalObjectId = $CurrentContext.Get('ServicePrincipalObjectId')
        azureUserObjectId = $CurrentContext.Get('AzureUserObjectId')
    }
    $CurrentContext.Set('KeyVaultResourceId', $keyvaultdeploy.keyVaultId.Value)
    $CurrentContext.Set('KeyVaultUri', $keyvaultdeploy.vaultUri.Value)

    Write-Host 'Getting Azure Automation Registration Info...'
    $CurrentContext.Set('AutomationAccountName', 'automation-#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('ResourceGroup') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')
    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    Write-Host 'Getting Storage Account Info...'
    $CurrentContext.Set('StorageAccountName', 'stackresources#{UDP}')
    $storageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('ResourceGroup')  -Name $CurrentContext.Get('StorageAccountName')
    if ($storageAccountKeys[0].Value.StartsWith('/')) { $storageKey = $storageAccountKeys[1].Value }
    else { $storageKey = $storageAccountKeys[0].Value }
    $CurrentContext.Set('StorageAccountKey', $storageKey)

    Write-Host 'Configuring KeyVault...'
  #  Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -EnabledForTemplateDeployment -EnabledForDiskEncryption 

    New-KeyVaultSecret -Name AutomationRegistrationKey -Value $automationRegInfo.PrimaryKey
    New-KeyVaultSecret -Name AutomationRegistrationUrl -Value $automationRegInfo.Endpoint
    
    New-KeyVaultSecret -Name StorageAccountKey -Value $CurrentContext.Get('StorageAccountKey')
    
    New-KeyVaultSecret -Name SqlAdminUsername -Value $CurrentContext.Get('SqlServerUsername')
    New-KeyVaultSecret -Name SqlAdminPassword -Value $CurrentContext.Get('SqlServerPassword')

    New-KeyVaultSecret -Name VMAdminUsername -Value $CurrentContext.Get('StackAdminUsername')
    New-KeyVaultSecret -Name VMAdminPassword -Value $CurrentContext.Get('StackAdminPassword')

    New-KeyVaultSecret -Name OctopusAutomationCredentialUsername -Value $CurrentContext.Get('OctopusAutomationCredentialUsername')
    New-KeyVaultSecret -Name OctopusAutomationCredentialPassword -Value $CurrentContext.Get('OctopusAutomationCredentialPassword')
    
    New-KeyVaultSecret -Name ServicePrincipalClientId -Value $CurrentContext.Get('ServicePrincipalClientId')
    New-KeyVaultSecret -Name ServicePrincipalClientSecret -Value $CurrentContext.Get('ServicePrincipalClientSecret')

    Write-Host 'Configuring Storage Account...'
    Publish-AutomationStackResources -SkipAuth -Upload StackResources
    Set-AzureRmCurrentStorageAccount -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Name $CurrentContext.Get('StorageAccountName') | Out-Null
    New-AzureStorageContainerStoredAccessPolicy -Container arm -Policy 'TemplateDeployment' -Permission r -ExpiryTime (Get-Date).AddHours(3) | Out-Null
}