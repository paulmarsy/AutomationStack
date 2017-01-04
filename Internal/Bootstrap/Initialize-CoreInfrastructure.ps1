function Initialize-CoreInfrastructure {
    Write-Host 'Deploying core infrastructure...'
    $CurrentContext.Set('InfraRg', 'AutomationStack#{UDP}')
    $CurrentContext.Set('SqlServerName', 'sqlserver#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -TemplateFile 'infrastructure.json' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('Username')
        sqlAdminPassword = $CurrentContext.Get('Password')
    }
}