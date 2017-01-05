function Initialize-CoreInfrastructure {
    $CurrentContext.Set('SqlServerName', 'sqlserver#{UDP}')
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('InfraRg') -Template 'infrastructure' -Mode Incremental -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        sqlAdminUsername = $CurrentContext.Get('Username')
    } | Out-Null
}