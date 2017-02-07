function Initialize-CoreInfrastructure {
    $CurrentContext.Set('SqlServerName', 'azuresql-#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'infrastructure' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('SqlServerUsername')
    } | Out-Null

    $CurrentContext.Set('StorageAccountName', 'stackresources#{UDP}')
    $storageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('ResourceGroup')  -Name $CurrentContext.Get('StorageAccountName')
    if ($storageAccountKeys[0].Value.StartsWith('/')) { $storageKey = $storageAccountKeys[1].Value }
    else { $storageKey = $storageAccountKeys[0].Value }
    $CurrentContext.Set('StorageAccountKey', $storageKey)

    Write-Host 'Getting Azure Automation Registration Info...'
    $CurrentContext.Set('AutomationAccountName', 'automation-#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('ResourceGroup') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')

    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    New-KeyVaultSecret -Name AutomationRegistrationKey -Value $automationRegInfo.PrimaryKey

    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'nsgrules' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
    } | Out-Null
}