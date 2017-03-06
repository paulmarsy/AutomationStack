function Upload-StackResources {
    param(
        [ValidateSet('BlobStorage','FileShare')]$Type,
        $Name,
        $Path,
        $Value,
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
    if ($Value -or -not (Get-Item -Path $Path).PSIsContainer) {
        $dest = $Tokenizer.Eval([System.IO.Path]::GetFileName($Path))
        $reference = switch ($Type) {
            'BlobStorage' { $storageLocation.CloudBlobContainer.GetBlockBlobReference($dest) }
            'FileShare' { $storageLocation.GetRootDirectoryReference().GetFileReference($dest) }
        }
        if ($Value) { $reference.UploadText($Value) }
        else { $reference.UploadFromFile(($Path | Convert-Path), [System.IO.FileMode]::Open) }
        [void][System.Console]::Out.WriteLineAsync("   `t`t`t`tUpload`t`t`t$dest")
        return
    }
    [void][System.Console]::Out.WriteLineAsync("  Runspace ID`tProgress`tAction`t`t`tFile`n$('-'*120)")
    $Path = Get-Item -Path $Path | % FullName
    if ($Type -eq 'FileShare') {
        Get-ChildItem -Path $Path -Recurse -Directory | % {
            $dest = $Tokenizer.Eval($_.FullName.Substring($Path.Length+1).Replace('\','/'))
            [void][System.Console]::Out.WriteLineAsync("  `t`t`t`tCreate Directory`t$dest")
            New-AzureStorageDirectory -Share $storageLocation -Path $dest -ErrorAction Ignore | Out-Null
        }
    }
    $totalCount = 0
    $totalSize = 0
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
        $totalCount++
        $assignedBatch = $batch | Sort-Object Size | Select-Object -First 1
        $assignedBatch.Size += $_.Length
        $totalSize += $_.Length
        $assignedBatch.Files.Add(@{
            Tokenised = $tokenised
            Dest = $Tokenizer.Eval($_.FullName.Substring($Path.Length+1).Replace('\','/'))
            Source = $source
            Length = $_.Length
        })
    } 
    $SharedState = [PSCustomObject]@{
        TotalSize = $totalSize
        Uploaded = 0
    }
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $sessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SharedState', $SharedState, $null)))
    $sessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('ProgressPreference', 'SilentlyContinue', $null)))
    $runspacePool = [RunspaceFactory]::CreateRunspacePool($UploadConcurrency, $UploadConcurrency, $sessionState, $Host)
    $runspacePool.Open()
    $startTime = Get-Date
    try {
        $jobs = for ($runspaceId = 0; $runspaceId -le $UploadConcurrency; $runspaceId++) {
            $pipeline = [powershell]::Create().AddScript({
                param($batch, $storageLocation, $runspaceId, $UploadConcurrency, $Type)
                $batch | % {
                    $file = $_
                    switch ($Type) {
                        'BlobStorage' { [void]($storageLocation | Set-AzureStorageBlobContent -File $file.Source -Blob $file.Dest -Force -ErrorAction Stop)}
                        'FileShare' { Set-AzureStorageFileContent -Share $storageLocation -Source $file.Source -Path $file.Dest -Force -ErrorAction Stop }
                    }
                    try {
                        [System.Threading.Monitor]::Enter($SharedState)
                        $SharedState.Uploaded += $file.Length
                        $percentComplete = $SharedState.Uploaded / $SharedState.TotalSize * 100
                    }
                    finally { [System.Threading.Monitor]::Exit($SharedState) } 

                    $percentComplete = [System.Math]::Round($percentComplete, 1).ToString('0.0').PadLeft(5)
                    $action = if ($file.Tokenised) { 'Tokenise & Upload' } else { "Upload`t`t" }
                    [void][System.Console]::Out.WriteLineAsync("  $runspaceId`t`t${percentComplete}%`t`t$action`t$(Split-Path -Leaf $file.Dest)")
                }
            }).AddArgument($batch[$runspaceId].Files).AddArgument($storageLocation).AddArgument($runspaceId).AddArgument($UploadConcurrency).AddArgument($Type)   
            $pipeline.RunspacePool = $runspacePool
            @{
                Pipeline = $pipeline
                Async = ($pipeline.BeginInvoke())
            }
        }
        do {    
            Start-Sleep -Seconds 1
            $running = $false
            $jobs.GetEnumerator() | % {
                if ($_.Async.IsCompleted) {
                    $_.Pipeline.EndInvoke($_.Async)
                    $_.Pipeline.Dispose()
                }
                else { $running = $true }
            }
        } while ($running)
        $byteRate = [Humanizer.ByteSizeExtensions]::Per([Humanizer.ByteSizeExtensions]::Bytes($totalSize), ((Get-Date) - $startTime))
        [void][System.Console]::Out.WriteLineAsync('Upload speed: {0}' -f $byteRate.Humanize('#.00', [Humanizer.Localisation.TimeUnit]::Second))

        if ($Type -eq 'BlobStorage') {
            $destCount = (Get-AzureStorageBlob -Container $Name -Context $Context).Count
            if ($destCount -ne $totalCount) {
                Write-Warning "Expected $totalCount files, found $destCount, retrying..."
                Upload-StackResources -Type:$Type -Name:$Name -Path:$Path -Value:$Value -FilesToTokenise:$FilesToTokenise -Tokenizer:$Tokenizer -Context:$Context
            } else {
                Write-Host "Expected $totalCount files & found $destCount"
            }
        }
    }
    finally {
        $runspacePool.Close()
    }
}