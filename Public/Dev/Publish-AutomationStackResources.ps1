function Publish-AutomationStackResources {
    param(
        [switch]$ResetStorage
    )
    Connect-AzureRmServicePrincipal
    try {
        Publish-StackResources -ResetStorage:$ResetStorage
        Publish-StackPackages
    }
    finally {
        Restore-AzureRmAuthContext
    }
}