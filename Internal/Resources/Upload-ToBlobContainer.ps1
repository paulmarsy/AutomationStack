function Upload-ToBlobContainer {
    param(
        [string]$Source,
        [string]$ContainerName,
        [string[]]$TokeniseFiles,
        $Context,
        [switch]$ResetStorage,
        $Octosprache
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
    [Console]::WriteLine("  Runspace ID`tAction`t`t`tFile`n$('-'*120)")
    Get-ChildItem -Path $sourcePath -Recurse -File | % {
        if ($_.Name -in $TokeniseFiles) {
            $sourceFile = Join-Path $TempPath $_.Name
            $Octosprache.ParseFile($_.FullName, $sourceFile)
            [Console]::WriteLine("  -`t`tTokenise & Upload`t$($_.Name)")
        } else {
            $sourceFile = $_.FullName
            [Console]::WriteLine("  -`t`tUpload`t`t`t$($_.Name)")
        }
        $storageContainer | Set-AzureStorageBlobContent -File $sourceFile -Blob $_.Name -Force -ConcurrentTaskCount $ConcurrentNetTasks | Out-Null
    }
}