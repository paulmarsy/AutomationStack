function Initialize-CoreInfrastructure {
    $CurrentContext.Set('SqlServerName', 'azuresql-#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'infrastructure' -Mode Incremental -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('SqlServerUsername')
    } | Out-Null

    $CurrentContext.Set('StorageAccountName', 'stackresources#{UDP}')
    $storageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('InfraRg')  -Name $CurrentContext.Get('StorageAccountName')
    if ($storageAccountKeys[0].Value.StartsWith('/')) { $storageKey = $storageAccountKeys[1].Value }
    else { $storageKey = $storageAccountKeys[0].Value }
    $CurrentContext.Set('StorageAccountKey', $storageKey)

    Write-Host 'Getting Azure Automation Registration Info...'
    $CurrentContext.Set('AutomationAccountName', 'automation-#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')

    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    New-KeyVaultSecret -Name AutomationRegistrationKey -Value $automationRegInfo.PrimaryKey

    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'nsgrules' -Mode Incremental -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
    } | Out-Null
}