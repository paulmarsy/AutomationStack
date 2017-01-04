function Upload-ToBlobContainer {
    param(
        [string]$Source,
        [string]$ContainerName,
        [string[]]$TokeniseFiles,
        $Context,
        [switch]$ResetStorage
    )

    $storageContainer = Get-AzureStorageContainer -Name $ContainerName -Context $Context -ErrorAction SilentlyContinue
    if ($ResetStorage) {
        Write-Host "Removing $ContainerName storage container"
        $storageContainer | Remove-AzureStorageContainer -Force -Context $Context
        return
    }
    if(!$storageContainer) {
        $storageContainer = New-AzureStorageContainer -Name $ContainerName -Context $Context -Permission Off
    }
    $sourcePath = Get-Item -Path $Source | % FullName
    Get-ChildItem -Path $sourcePath -Recurse -File | % {
        if ($_.Name -in $TokeniseFiles) {
            [Console]::WriteLine("Tokenising $($_.Name)")
            $sourceFile = Join-Path $TempPath $_.Name
            $CurrentContext.ParseFile($_.FullName, $sourceFile)
        } else {
            $sourceFile = $_.FullName
        }
        [Console]::WriteLine("Uploading $($_.Name)")
        $storageContainer | Set-AzureStorageBlobContent -File $sourceFile -Blob $_.Name -Force -ConcurrentTaskCount $ConcurrentTaskCount | Out-Null
    }
}