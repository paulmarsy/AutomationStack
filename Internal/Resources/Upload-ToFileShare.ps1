function Upload-ToFileShare {
    param(
        [string]$Source,
        [string]$FileShareName,
        [string[]]$TokeniseFiles,
        $Context,
        [switch]$ResetStorage,
        $Octosprache
    )

    const UploadConcurrency = ([System.Environment]::ProcessorCount * 2)

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
        $dest = $Octosprache.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
        [void][System.Console]::Out.WriteLineAsync("  -`t`tCreate Directory`t$dest")
        New-AzureStorageDirectory -Share $fileShare -Path $dest -ErrorAction Ignore | Out-Null
    }
    $batch = @{}
    0..$UploadConcurrency | % { $batch[$_ % $UploadConcurrency] = {@()}.Invoke() }
    $i = 0
    Get-ChildItem -Path $sourcePath -Recurse -File | Sort-Object -Descending -Property Length | % {
        if ($_.Name -in $TokeniseFiles) {
            $sourceFile = (Join-Path $TempPath $_.Name)
            $Octosprache.ParseFile($_.FullName, $sourceFile)
            $tokenised = $true
        } else {
            $sourceFile = $_.FullName
            $tokenised = $false
        }
        $batch[$i % $UploadConcurrency].Add(@{
            Tokenised = $tokenised
            Dest = $Octosprache.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
            Source = $sourceFile
        })
        $i++
    }
    $jobs = for ($runspaceId = 0; $runspaceId -lt $UploadConcurrency; $runspaceId++) {
        $ps = [powershell]::Create().AddScript({
            param($batch, $fileShare, $runspaceId, $UploadConcurrency)   
            $batch | % {
                $file = $_
                if ($file.Tokenised) {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tTokenise & Upload`t$(Split-Path -Leaf $file.Dest)")
                } else {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tUpload`t`t`t$(Split-Path -Leaf $file.Dest)")
                }
                
                Set-AzureStorageFileContent -Share $fileShare -Source $file.Source -Path $file.Dest -Force -ErrorAction Stop
            }
        }).AddArgument($batch[$runspaceId]).AddArgument($fileShare).AddArgument($runspaceId).AddArgument($UploadConcurrency)
        @{
            PowerShell = $ps
            Async = ($ps.BeginInvoke())
        }
    }
    do {
        $running = $false
        $jobs.GetEnumerator() | % {
            if ($_.Async.IsCompleted) {
                $_.Powershell.EndInvoke($_.Async)
                $_.PowerShell.Dispose()
            }
            else { $running = $true }
        }
    } while ($running)
}