function Suspend-AutomationStack {
    param([switch]$RemoveResourceGroup)
    $rg = $CurrentContext.Get('OctopusRg')
    $vmName = $CurrentContext.Get('OctopusVMName')

    Write-Host 'Connecting to storage accounts... ' -NoNewLine
    $srcStorageAccountName = Get-AzureRmStorageAccount -ResourceGroupName $rg | % StorageAccountName
    $srcStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rg -Name $srcStorageAccountName)[0].Value
    $srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccountKey
    $dstContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if (!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off | Out-Null
    }
    Write-Host 'connected' -ForegroundColor Green

    Write-Host "Stopping $vm... " -NoNewLine
    Stop-AzureRmVM -ResourceGroupName $rg -Name $vmName -Force | Out-Null
    Write-Host 'stopped' -ForegroundColor Green

    Write-Host 'Exporting Resource Group Template... ' -NoNewLine
    $templateFile = Join-Path $TempPath ('{0}.{1}.json' -f $rg, $vmName)
    Export-AzureRmResourceGroup -ResourceGroupName $rg -Path $templateFile -IncludeParameterDefaultValue -Force -WarningVariable templateErrors -WarningAction SilentlyContinue | Out-Null
    Write-Host 'exported' -ForegroundColor Green
    $templateErrors | Write-Warning

    Write-Host "Uploading Resource Group Template to $($dstContext.StorageAccountName)... " -NoNewLine
    $dstContainer | Set-AzureStorageBlobContent -File $templateFile -Blob 'OctopusVM.json' -Force | Out-Null
    Write-Host 'uploaded' -ForegroundColor Green

    $blobName = 'OctopusVM-OS.vhd'
    Write-Host "Copying $blobName from $($srcContext.StorageAccountName) to $($dstContext.StorageAccountName)... " -NoNewLine
    $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer vhds -SrcBlob $blobName -DestContext $dstContext -DestContainer images -DestBlob $blobName -Force
    $copyBlob | Get-AzureStorageBlobCopyState -WaitForComplete | Out-Null
    Write-Host 'copied' -ForegroundColor Green

    if ($RemoveResourceGroup) {
        Write-Host 'Removing Resource Group... ' -NoNewLine
        Remove-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName 
        Write-Host 'removed' -ForegroundColor Green
    }
}