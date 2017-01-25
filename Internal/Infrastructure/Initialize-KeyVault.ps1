function Initialize-KeyVault {
    $CurrentContext.Set('KeyVaultName', 'keyvault-#{UDP}')
    $keyvaultdeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'keyvault' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        tenantId = $CurrentContext.Get('AzureTenantId')
        objectId = $CurrentContext.Get('ServicePrincipalObjectId')
    }
    $CurrentContext.Set('KeyVaultResourceId', $keyvaultdeploy.keyVaultId.Value)
    $CurrentContext.Set('KeyVaultUri', $keyvaultdeploy.vaultUri.Value)

    Get-AzureRmContext | % Account | ? AccountType -eq 'User' | % {
        $azureAdUserObject = Get-AzureRmADUser -UserPrincipalName $_.Id =ErrorAction Ignore
        if ($azureAdUserObject) {
            Write-Host 'Granting authenticated user full permissions to KeyVault'
            Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ObjectId $azureAdUserObject.Id.Guid -PermissionsToKeys all -PermissionsToSecrets all -ResourceGroupName $CurrentContext.Get('InfraRg')
        }
    }

    Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Get('KeyVaultName') -ResourceGroupName $CurrentContext.Get('InfraRg') -EnabledForTemplateDeployment -EnabledForDiskEncryption 
           
    New-KeyVaultSecret -Name StackAdminPassword -Value $CurrentContext.Get('StackAdminPassword')
    New-KeyVaultSecret -Name SqlAdminPassword -Value $CurrentContext.Get('SqlServerPassword')
    New-KeyVaultSecret -Name VMAdminPassword -Value $CurrentContext.Get('StackAdminPassword')
    New-KeyVaultSecret -Name OctopusServiceAccountPassword -Value $CurrentContext.Get('OctopusAutomationCredentialPassword')
    New-KeyVaultSecret -Name ServicePrincipalClientSecret -Value $CurrentContext.Get('ServicePrincipalClientSecret')

}