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
        [Console]::WriteLine("  Runspace ID`tAction`t`t`tFile`n$('-'*120)")
    $sourcePath = Get-Item -Path $Source | % FullName
    Get-ChildItem -Path $sourcePath -Recurse -Directory | % {
        $dest = $CurrentContext.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
        [Console]::WriteLine("  -`t`tCreate Directory`t$dest")
        New-AzureStorageDirectory -Share $fileShare -Path $dest -ConcurrentTaskCount $ConcurrentNetTasks -ErrorAction Ignore | Out-Null
    }
    $items = Get-ChildItem -Path $sourcePath -Recurse -File
    $batchSize = [System.Math]::Max(([System.Math]::Ceiling(($items.Count / $ConcurrentNetTasks))), 5)
    $jobs ={@()}.Invoke()
    $runspaceId = 0
    for ($i = 0; $i -lt $items.Count; $i = $i + $batchSize) {
        $runspaceId++
        $batch = @($i..($i+$batchSize) | ? { $null -ne $items[$_] } |  % {
            $item = $items[$_]
            if ($item.Name -in $TokeniseFiles) {
                    $sourceFile = (Join-Path $TempPath $item.Name)
                    $CurrentContext.ParseFile($item.FullName, $sourceFile)
                    $tokenised = $true
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
            param($batch, $fileShare, $runspaceId, $ConcurrentNetTasks)   
            $batch | % {
                if ($_.Tokenised) {
                    [Console]::WriteLine("  $runspaceId`t`tTokenise & Upload`t$(Split-Path -Leaf $_.Dest)")
                } else {
                    [Console]::WriteLine("  $runspaceId`t`tUpload`t`t`t$(Split-Path -Leaf $_.Dest)")
                }
                Set-AzureStorageFileContent -Share $fileShare -Source $_.Source -Path $_.Dest -Force -ConcurrentTaskCount $ConcurrentNetTasks -ErrorAction Stop
            }
        }).AddArgument($batch).AddArgument($fileShare).AddArgument($runspaceId).AddArgument($ConcurrentNetTasks)
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