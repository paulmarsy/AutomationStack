function Publish-AutomationStackResources {
    param(        
        [ValidateSet('AzureCustomScripts','DSCConfigurations','OctopusDeployDataSet','TeamCityDataSet','NuGetPackages','All')]$Upload = 'All',
        [switch]$ResetStorage
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