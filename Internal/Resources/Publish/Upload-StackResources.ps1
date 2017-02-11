function Upload-StackResources {
    param(
        [ValidateSet('BlobStorage','FileShare')]$Type,
        $Name,
        $Path,
        $FilesToTokenise = @(),
        $Tokenizer,
        $Context
    )

    const UploadConcurrency = ([System.Environment]::ProcessorCount * 2)

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
    $batch = @{}
    0..$UploadConcurrency | % { $batch[$_ % $UploadConcurrency] = {@()}.Invoke() }
    $i = 0
    Get-ChildItem -Path $Path -Recurse -File | Sort-Object -Descending -Property Length | % {
        if ($_.Name -in $FilesToTokenise) {
            $source = Join-Path $TempPath $_.Name
            $Tokenizer.ParseFile($_.FullName, $source)
            $tokenised = $true
        } else {
            $source = $_.FullName
            $tokenised = $false
        }
        $batch[$i % $UploadConcurrency].Add(@{
            Tokenised = $tokenised
            Dest = $Tokenizer.Eval($_.FullName.Substring($Path.Length+1).Replace('\','/'))
            Source = $source
        })
        $i++
    }
    $jobs = for ($runspaceId = 0; $runspaceId -lt $UploadConcurrency; $runspaceId++) {
        $ps = [powershell]::Create().AddScript({
            param($batch, $storageLocation, $runspaceId, $UploadConcurrency, $Type)   
            $batch | % {
                $file = $_
                if ($file.Tokenised) {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tTokenise & Upload`t$(Split-Path -Leaf $file.Dest)")
                } else {
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`tUpload`t`t`t$(Split-Path -Leaf $file.Dest)")
                }
                switch ($Type) {
                    'BlobStorage' { $storageLocation | Set-AzureStorageBlobContent -File $file.Source -Blob $file.Dest -Force -ErrorAction Stop | Out-Null }
                    'FileShare' { Set-AzureStorageFileContent -Share $storageLocation -Source $file.Source -Path $file.Dest -Force -ErrorAction Stop }
                }
                
            }
        }).AddArgument($batch[$runspaceId]).AddArgument($storageLocation).AddArgument($runspaceId).AddArgument($UploadConcurrency).AddArgument($Type)
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