function Initialize-CoreInfrastructure {
    Write-Host "Creating Tags..."
    New-AzureRmTag -Name application -Value AutomationStack
    New-AzureRmTag -Name udp -Value $CurrentContext.Get('UDP') 

    Invoke-SharedScript Resources 'New-ResourceGroup' -UDP $CurrentContext.Get('UDP') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Location ($CurrentContext.Get('AzureRegion'))

    $coreInfrastructureDeploy = Start-ARMDeployment -Mode File -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'coreinfrastructure' -TemplateParameters @{
        startTemplateDeploymentRunbookUri = (ConvertTo-SecureString -String (Upload-AzureTemporaryFile -Path (Join-Path -Resolve $ResourcesPath 'Runbooks\StartTemplateDeployment.ps1')) -AsPlainText -Force)
        infrastructureRunbookUri = (ConvertTo-SecureString -String (Upload-AzureTemporaryFile -Path (Join-Path -Resolve $ResourcesPath 'Runbooks\DeployInfrastructure.ps1')) -AsPlainText -Force)
        servicePrincipalCertificateValue = (ConvertTo-SecureString -String $CurrentContext.Get('ServicePrincipalCertificate') -AsPlainText -Force)
        servicePrincipalCertificateThumbprint = $CurrentContext.Get('ServicePrincipalCertificateThumbprint')
        servicePrincipalApplicationId = $CurrentContext.Get('ServicePrincipalClientId')
        servicePrincipalObjectId = $CurrentContext.Get('ServicePrincipalObjectId')
        azureUserObjectId = $CurrentContext.Get('AzureUserObjectId')
    }
    $CurrentContext.Set('KeyVaultResourceId', $coreInfrastructureDeploy.keyVaultResourceId.Value)

    Write-Host "`nGetting Azure Automation Registration Info..."
    $CurrentContext.Set('AutomationAccountName', 'automation-#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('ResourceGroup') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')
    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    Write-Host "`nGetting Storage Account Info..."
    $CurrentContext.Set('StorageAccountName', 'stackresources#{UDP}')
    $storageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('ResourceGroup')  -Name $CurrentContext.Get('StorageAccountName')
    if ($storageAccountKeys[0].Value.StartsWith('/')) { $storageKey = $storageAccountKeys[1].Value }
    else { $storageKey = $storageAccountKeys[0].Value }
    $CurrentContext.Set('StorageAccountKey', $storageKey)

    Write-Host "`nConfiguring KeyVault..."
    Set-AzureRmKeyVaultAccessPolicy -VaultName $CurrentContext.Eval('keyvault-#{UDP}') -ResourceGroupName $CurrentContext.Get('ResourceGroup') -EnabledForTemplateDeployment -EnabledForDiskEncryption 

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

    Write-Host "`nConfiguring Storage Account..."
    Publish-AutomationStackResources -SkipAuth -Upload Infrastructure
}