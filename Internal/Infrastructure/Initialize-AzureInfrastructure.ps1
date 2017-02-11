function Initialize-AzureInfrastructure {
    Start-ARMDeployment -Mode Uri -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template 'azuredeploy.json' -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
    } | Out-Null
}