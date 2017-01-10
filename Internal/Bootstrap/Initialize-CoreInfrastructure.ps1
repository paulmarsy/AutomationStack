function Initialize-CoreInfrastructure {
    $CurrentContext.Set('SqlServerName', 'sqlserver#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'infrastructure' -Mode Incremental -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('Username')
    } | Out-Null

    Write-Host 'Getting Azure Automation Registration Info...'
    $CurrentContext.Set('AutomationAccountName', 'automation#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')

    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    $registrationKey = ConvertTo-SecureString -String $automationRegInfo.PrimaryKey -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName $CurrentContext.Get('KeyVaultName') -Name 'AutomationRegistrationKey' -SecretValue $registrationKey | Out-Null

    Write-Host 'Provisioning Network Security Groups...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'nsgrules' -Mode Incremental -TemplateParameters @{} | Out-Null
}