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
    Get-ChildItem -Path $sourcePath -Recurse -Directory | % {
        $dest = $CurrentContext.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
        [Console]::WriteLine("Creating directory $dest")
        New-AzureStorageDirectory -Share $fileShare -Path $dest -ErrorAction Ignore | Out-Null
    }
    $items = Get-ChildItem -Path $sourcePath -Recurse -File
    $batchSize = [System.Math]::Max(([System.Math]::Ceiling(($items.Count / $ConcurrentTaskCount))), $ConcurrentTaskCount)
    $jobs ={@()}.Invoke()
    $runspaceId = 0
    for ($i = 0; $i -lt $items.Count; $i = $i + $batchSize) {
        $runspaceId++
        $batch = @($i..($i+$batchSize) | ? { $null -ne $items[$_] } |  % {
            $item = $items[$_]
            if ($item.Name -in $TokeniseFiles) {
                    $sourceFile = (Join-Path $TempPath $item.Name)
                    $CurrentContext.ParseFile($item.FullName, $sourceFile)
            } else {
                    $sourceFile = $item.FullName
                    $tokenised = $false
            }
            @{
                Tokenised = $tokenised
                Dest = $CurrentContext.Eval($item.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
                Source = $sourceFile
            }
        })
        $ps = [powershell]::Create().AddScript({
            param($batch, $fileShare, $runspaceId, $ConcurrentTaskCount)   
            $batch | % {
                if ($_.Tokenised) {
                    [Console]::WriteLine("[$runspaceId] Uploading Tokenised $(Split-Path -Leaf $_.Dest)")
                } else {
                    [Console]::WriteLine("[$runspaceId] Uploading $(Split-Path -Leaf $_.Dest)")
                }
                Set-AzureStorageFileContent -Share $fileShare -Source $_.Source -Path $_.Dest -Force -ConcurrentTaskCount $ConcurrentTaskCount -ErrorAction Stop
            }
        }).AddArgument($batch).AddArgument($fileShare).AddArgument($runspaceId).AddArgument($ConcurrentTaskCount)
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