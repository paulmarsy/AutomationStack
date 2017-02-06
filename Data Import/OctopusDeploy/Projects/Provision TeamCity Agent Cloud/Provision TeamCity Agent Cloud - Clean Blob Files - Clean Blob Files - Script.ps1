$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

Remove-AzureStorageContainer -Name vhds -Force -Context $context
Remove-AzureStorageContainer -Name system -Force -Context $context