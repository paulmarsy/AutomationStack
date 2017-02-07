function Suspend-AutomationStack {
    $rg = $CurrentContext.Get('OctopusRg')
    $vmName = $CurrentContext.Get('OctopusVMName')

    Write-Host 'Connecting to storage accounts... ' -NoNewLine
    $srcStorageAccountName = Get-AzureRmStorageAccount -ResourceGroupName $rg | % StorageAccountName
    $srcStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rg -Name $srcStorageAccountName)[0].Value
    $srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccountKey
    $dstContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if (!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off | Out-Null
    }
    Write-Host 'connected' -ForegroundColor Green

    Write-Host "Stopping $vmName... " -NoNewLine
    Stop-AzureRmVM -ResourceGroupName $rg -Name $vmName -Force | Out-Null
    Write-Host 'stopped' -ForegroundColor Green

    $blobName = 'OctopusVM-OS.vhd'
    Write-Host "Copying $blobName from $($srcContext.StorageAccountName) to $($dstContext.StorageAccountName)... "
    $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer vhds -SrcBlob $blobName -DestContext $dstContext -DestContainer images -DestBlob $blobName -Force -Verbose
    $copyState = $copyBlob | Get-AzureStorageBlobCopyState
    while ($copyState.Status -ne "Success")
    {   
        Start-Sleep -Seconds 5
        $copyState = $copyBlob | Get-AzureStorageBlobCopyState
        $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
        Write-Host "Completed $('{0:N2}' -f $percent)%"
        Write-Progress -Activity "Copying $blobName from $($srcContext.StorageAccountName) to $($dstContext.StorageAccountName)" -CurrentOperation "$($copyState.Status) $('{0:N2}' -f $percent)% $percent" -PercentComplete $percent
    }

    Write-Host 'Removing Resource Group... ' -NoNewLine
    Remove-AzureRmResourceGroup -ResourceGroupName $rg -Force
    Write-Host 'removed' -ForegroundColor Green
]}