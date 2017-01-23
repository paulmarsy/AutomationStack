param($VHDUri, $SrcResourceGroupName, $DstResourceGroupName,$DstStorageAccount, $DstBlob)

Write-Host 'Connecting to source storage account... '
if ($VHDUri -match 'http:\/\/(?<accountname>[a-zA-Z0-9]+)\.blob\.core\.windows\.net\/(?<containername>[a-zA-Z]+)\/(?<blobname>.+)') {
    $srcStorageAccount = $Matches['accountname']
    $srcContainer =  $Matches['containername']
    $srcBlob =  $Matches['blobname']
} else {
    throw "Unable to identify VM Image storage account details from $VHDUri"
}
$srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $SrcResourceGroupName -Name $srcStorageAccount)[0].Value)


Write-Host 'Connecting to destination storage account... '
$dstContext = New-AzureStorageContext -StorageAccountName $DstStorageAccount -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $DstResourceGroupName -Name $DstStorageAccount)[0].Value)
$dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
if(!$dstContainer) {
    $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off
}

Write-Host 'Copying VM Image to Storage Account... '
$copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob -DestContext $dstContext -DestContainer images -DestBlob $DstBlob -Force
$copyState = $copyBlob | Get-AzureStorageBlobCopyState
while ($copyState.Status -ne "Success")
{   
    Start-Sleep -Seconds 5
    $copyState = $copyBlob | Get-AzureStorageBlobCopyState
    $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
    Write-Host "Completed $('{0:N2}' -f $percent)%"
}