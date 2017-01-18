function Suspend-AutomationStack {
    param(
        $ResourceGroupName = $CurrentContext.Get('OctopusRg')
    )

    Write-Host 'Stopping Azure VMs... ' -NoNewLine
    Get-AzureRmVm -ResourceGroupName $ResourceGroupName | Stop-AzureRmVm -Force
    Write-Host 'stopped' -ForegroundColor Green

    Write-Host 'Exporting Resource Group Template... ' -NoNewLine
    $templateFile = Join-Path $TempPath ('{0}.json' -f $ResourceGroupName)
    Export-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -Path $templateFile -IncludeParameterDefaultValue -Force | Out-Null
    Write-Host 'exported' -ForegroundColor Green

    Write-Host 'Connecting to storage accounts... ' -NoNewLine
    $dstContext = New-AzureStorageContext -StorageAccountName $DstStorageAccount -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $DstResourceGroupName -Name $DstStorageAccount)[0].Value)
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if(!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off
    }
    Write-Host 'connected' -ForegroundColor Green

    Write-Host 'Copying VM Image to Storage Account... ' -NoNewLine
    $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob -DestContext $dstContext -DestContainer images -DestBlob $DstBlob -Force
    $copyBlob | Get-AzureStorageBlobCopyState -WaitForComplete
        Write-Host 'copied' -ForegroundColor Green

    Write-Host 'Removing Resource Group... ' -NoNewLine
    Remove-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName 
        Write-Host 'removed' -ForegroundColor Green

}