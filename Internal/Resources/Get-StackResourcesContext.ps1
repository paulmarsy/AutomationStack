function Get-StackResourcesContext {
    New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')  -Protocol Https
}