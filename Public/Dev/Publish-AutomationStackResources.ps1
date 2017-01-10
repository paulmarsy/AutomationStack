function Publish-AutomationStackResources {
    param(
        [switch]$CompileDSC,
        [switch]$ResetStorage
    )
    Connect-AzureRmServicePrincipal
    try {
        Publish-StackResources -ResetStorage:$ResetStorage
        if ($CompileDSC) {
            Import-AzureRmAutomationDscConfiguration -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Force -Published -SourcePath (Join-Path -Resolve $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1' | Convert-Path)
            Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -ConfigurationName 'OctopusDeploy' -Parameters @{
                UDP = $CurrentContext.Get('UDP')
                OctopusAdminUsername = $CurrentContext.Get('Username')
                OctopusAdminPassword = $CurrentContext.Get('Password')
                ConnectionString = $CurrentContext.Get('OctopusConnectionString')
                HostHeader = $CurrentContext.Get('OctopusHostHeader')
            }

            Import-AzureRmAutomationDscConfiguration -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Force -Published -SourcePath (Join-Path -Resolve $ResourcesPath 'DSC Configurations\TeamCity.ps1' | Convert-Path)
            Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -ConfigurationName 'TeamCity' -Parameters @{
                ApiKey = $CurrentContext.Get('ApiKey')
                OctopusServerUrl = $CurrentContext.Get('OctopusHostHeader')
            }
        }
    }
    finally {
        Restore-AzureRmAuthContext
    }
}