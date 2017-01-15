function Initialize-CoreInfrastructure {
    $CurrentContext.Set('SqlServerName', 'sqlserver#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'infrastructure' -Mode Incremental -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('StackAdminUsername')
    } | Out-Null

    Write-Host 'Getting Azure Automation Registration Info...'
    $CurrentContext.Set('AutomationAccountName', 'automation#{UDP}')
    $automationRegInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName')

    $CurrentContext.Set('AutomationRegistrationUrl', $automationRegInfo.Endpoint)

    New-KeyVaultSecret -Name AutomationRegistrationKey -Value $automationRegInfo.PrimaryKey

    Write-Host 'Provisioning Network Security Groups...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'nsgrules' -Mode Incremental -TemplateParameters @{} | Out-Null
}