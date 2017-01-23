function Publish-AutomationStackResources {
    param(
        [switch]$ResetStorage,
        [ValidateSet('AzureCustomScripts','DSCConfigurations','OctopusDeployDataSet','TeamCityDataSet','NuGetPackages','All')]$Upload = 'All'
    )
    Connect-AzureRmServicePrincipal
    try {
        Publish-StorageAccountResources -ResetStorage:$ResetStorage -Upload:$Upload
        if ($Upload -in @('All','NuGetPackages')) {
            Publish-OctopusNuGetPackages
        }
    }
    finally {
        Restore-AzureRmAuthContext
    }
}