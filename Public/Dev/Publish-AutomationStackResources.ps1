function Publish-AutomationStackResources {
    param(
        [switch]$ResetStorage,
        [ValidateSet('ARM','DSC','OctopusDeploy','TeamCity','All')]$Upload = 'All'
    )
    Connect-AzureRmServicePrincipal
    try {
        Publish-StackResources -ResetStorage:$ResetStorage -Upload:$Upload
        Publish-StackPackages
    }
    finally {
        Restore-AzureRmAuthContext
    }
}