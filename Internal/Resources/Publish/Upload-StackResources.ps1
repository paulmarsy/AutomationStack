function Upload-StackResources {
    param(
        [ValidateSet('BlobStorage','FileShare')]$Type,
        $Name,
        $Path,
        $FilesToTokenise = @(),
        $Tokenizer,
        $Context
    )
    const UploadConcurrency = 12

    $storageLocation = switch ($Type) {
        'BlobStorage' { Get-AzureStorageContainer -Name $Name -Context $Context -ErrorAction Ignore }
        'FileShare' { Get-AzureStorageShare -Name $Name -Context $Context -ErrorAction Ignore }
    }
    if (!$storageLocation) {
        $storageLocation = switch ($Type) {
            'BlobStorage' { New-AzureStorageContainer -Name $Name -Context $Context -Permission Off }
            'FileShare' { New-AzureStorageShare -Name $Name -Context $Context }
        }
    }
    $Path = Get-Item -Path $Path | % FullName
    if ($Type -eq 'FileShare') {
        [Console]::WriteLine("  Runspace ID`tAction`t`t`tFile`n$('-'*120)")
        Get-ChildItem -Path $Path -Recurse -Directory | % {
            $dest = $Tokenizer.Eval($_.FullName.Substring($Path.Length+1).Replace('\','/'))
            [void][System.Console]::Out.WriteLineAsync("  -`t`tCreate Directory`t$dest")
            New-AzureStorageDirectory -Share $storageLocation -Path $dest -ErrorAction Ignore | Out-Null
        }
    }
    $batch = @()
    0..$UploadConcurrency | % { $batch += New-Object psobject -Property @{ Size = 0; Files = {@()}.Invoke() } }
    Get-ChildItem -Path $Path -Recurse -File | Sort-Object -Descending -Property Length | % {
        if ($_.Name -in $FilesToTokenise) {
            $source = Join-Path $TempPath $_.Name
            $Tokenizer.ParseFile($_.FullName, $source)
            $tokenised = $true
        } else {
            $source = $_.FullName
            $tokenised = $false
        }
        $assignedBatch = $batch | Sort-Object Size | Select-Object -First 1
        $assignedBatch.Size += $_.Length
        $assignedBatch.Files.Add(@{
            Tokenised = $tokenised
            Dest = $Tokenizer.Eval($_.FullName.Substring($Path.Length+1).Replace('\','/'))
            Source = $source
        })
    }
    $jobs = for ($runspaceId = 0; $runspaceId -lt $UploadConcurrency; $runspaceId++) {
        $ps = [powershell]::Create().AddScript({
            param($batch, $storageLocation, $runspaceId, $UploadConcurrency, $Type)   
            $batch | % {
                $file = $_
                switch ($Type) {
                    'BlobStorage' { [void]($storageLocation | Set-AzureStorageBlobContent -File $file.Source -Blob $file.Dest -Force -ErrorAction Stop)}
                    'FileShare' { Set-AzureStorageFileContent -Share $storageLocation -Source $file.Source -Path $file.Dest -Force -ErrorAction Stop }
                }
                if ($file.Tokenised) {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tTokenise & Upload`t$(Split-Path -Leaf $file.Dest)")
                } else {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tUpload`t`t`t$(Split-Path -Leaf $file.Dest)")
                }
            }
        }).AddArgument($batch[$runspaceId].Files).AddArgument($storageLocation).AddArgument($runspaceId).AddArgument($UploadConcurrency).AddArgument($Type)
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