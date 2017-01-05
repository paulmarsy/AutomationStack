function Initialize-KeyVault {
    $CurrentContext.Set('KeyVaultName', 'keyvault#{UDP}')
    $keyvaultdeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'keyvault' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        tenantId = $CurrentContext.Get('AzureTenantId')
        objectId = $CurrentContext.Get('ServicePrincipalObjectId')
        sqlAdminPassword = $CurrentContext.Get('Password')
        vmAdminPassword = $CurrentContext.Get('Password')
        servicePrincipalClientSecret = $CurrentContext.Get('ServicePrincipalClientSecret')
    }
    $CurrentContext.Set('KeyVaultResourceId', $keyvaultdeploy.keyVaultId.Value)
    $CurrentContext.Set('KeyVaultUri', $keyvaultdeploy.vaultUri.Value)

    $account = Get-AzureRmContext | % Account
    if ($account.AccountType -eq 'User') {
        Write-Host 'Granting current authenticated user full permissions to KeyVault'
        $azureAdUserObject = Get-AzureRmADUser -UserPrincipalName $account.Id
        Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ObjectId $azureAdUserObject.Id.Guid -PermissionsToKeys all -PermissionsToSecrets all -ResourceGroupName $CurrentContext.Get('InfraRg')
    }

    Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ResourceGroupName $CurrentContext.Get('InfraRg') -EnabledForTemplateDeployment -EnabledForDiskEncryption 
}