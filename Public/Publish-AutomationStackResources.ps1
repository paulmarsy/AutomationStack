function Publish-AutomationStackResources {
    param([switch]$ResetStorage)
    Publish-StackResources -ResetStorage:$ResetStorage
}