function Upload-ToFileShare {
    param(
        [string]$Source,
        [string]$FileShareName,
        [string[]]$TokeniseFiles,
        $Context,
        [switch]$ResetStorage
    )

    $fileShare = Get-AzureStorageShare -Name $FileShareName -Context $Context -ErrorAction SilentlyContinue
    if ($ResetStorage) {
        Write-Host "Removing $FileShareName storage share"
        $fileShare | Remove-AzureStorageShare -Force -Context $Context
        return
    }
    if(!$fileShare) {
        $fileShare = New-AzureStorageShare -Name $FileShareName -Context $Context
    }
    $sourcePath = Get-Item -Path $Source | % FullName
    $items = Get-ChildItem -Path $sourcePath -Recurse -File
    $batchSize = [System.Math]::Max(([System.Math]::Ceiling(($items.Count / $ConcurrentTaskCount))), $ConcurrentTaskCount)
    $jobs ={@()}.Invoke()
    $runspaceId = 0
    for ($i = 0; $i -lt $items.Count; $i = $i + $batchSize) {
        $runspaceId++
        $batch = @($i..($i+$batchSize) | ? { $null -ne $items[$_] } |  % { $items[$_] })
        $ps = [powershell]::Create().AddScript({
            param($batch, $CurrentContext, $TokeniseFiles, $fileShare, $sourcePath, $runspaceId, $ConcurrentTaskCount)
            $batch | % {
                if ($_.Name -in $TokeniseFiles) {
                    [Console]::WriteLine("[$runspaceId] Tokenising $($_.Name)")
                    $sourceFile = Join-Path $TempPath $_.Name | Convert-Path
                    $CurrentContext.ParseFile($_.FullName, $sourceFile)
                } else {
                    $sourceFile = $_.FullName
                }
                $destFolder = $_.FullName.Substring($sourcePath.Length)
               $destFile = $CurrentContext.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
                [Console]::WriteLine("[$runspaceId] Uploading $destFile")
                New-AzureStorageDirectory -Share $fileShare -Path ([System.IO.Path]::GetDirectoryName($destFile)) -ErrorAction Ignore -ConcurrentTaskCount $ConcurrentTaskCount | Out-Null
               Set-AzureStorageFileContent -Share $fileShare -Source $sourceFile -Path $destFile -Force --ConcurrentTaskCount $ConcurrentTaskCount
            }
        }).AddArgument($batch).AddArgument($CurrentContext).AddArgument($TokeniseFiles).AddArgument($fileShare).AddArgument($sourcePath).AddArgument($runspaceId).AddArgument($ConcurrentTaskCount)
        $jobs.Add(@{
            PowerShell = $ps
            Async = ($ps.BeginInvoke())
        })
    }
    do {
        $running = $false
        $jobs.GetEnumerator() | % {
            if ($_.Async.IsCompleted) { $_.Powershell.EndInvoke($_.Async) }
            else { $running = $true }
        }
    } while ($running)
}