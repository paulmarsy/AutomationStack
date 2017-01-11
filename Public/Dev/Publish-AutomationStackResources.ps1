function Publish-AutomationStackResources {
    param(
        [switch]$ResetStorage
    )
    Connect-AzureRmServicePrincipal
    try {
        Publish-StackResources -ResetStorage:$ResetStorage
    }
    finally {
        Restore-AzureRmAuthContext
    }
}