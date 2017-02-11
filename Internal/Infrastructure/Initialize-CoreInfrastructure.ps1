function Initialize-CoreInfrastructure {
    Get-AzureRmContext | % Account | ? AccountType -eq 'User' | % Id | % { Get-AzureRmADUser -UserPrincipalName $_ -ErrorAction Ignore } | ? { $null -ne $_ } | % {
        Write-Host "User $($_.DisplayName) will be given full permission to KeyVault"
        $CurrentContext.Set('AdminUserObjectId', $_.Id.Guid)
    }
    
    $CurrentContext.Set('KeyVaultName', 'keyvault-#{UDP}')
    $coreInfrastructureDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'coreinfrastructure' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        servicePrincipalObjectId = $CurrentContext.Get('ServicePrincipalObjectId')
        adminUserObjectId = $CurrentContext.Get('AdminUserObjectId')
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
    Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -EnabledForTemplateDeployment -EnabledForDiskEncryption 

    New-KeyVaultSecret -Name AutomationRegistrationKey -Value $automationRegInfo.PrimaryKey
    New-KeyVaultSecret -Name StorageAccountKey -Value $CurrentContext.Get('StorageAccountKey')
    New-KeyVaultSecret -Name StackAdminPassword -Value $CurrentContext.Get('StackAdminPassword')
    New-KeyVaultSecret -Name SqlAdminPassword -Value $CurrentContext.Get('SqlServerPassword')
    New-KeyVaultSecret -Name VMAdminPassword -Value $CurrentContext.Get('StackAdminPassword')
    New-KeyVaultSecret -Name OctopusAutomationCredentialPassword -Value $CurrentContext.Get('OctopusAutomationCredentialPassword')
    New-KeyVaultSecret -Name ServicePrincipalClientSecret -Value $CurrentContext.Get('ServicePrincipalClientSecret')
}