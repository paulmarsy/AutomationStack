function Suspend-AutomationStack {
    Write-Host 'Stopping VM...'
    Stop-AzureRmVM -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -Force

    Write-Host 'Generalizing VM...'
    Set-AzureRmVM -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -Generalized

    Write-Host 'Saving VM Image...'
    $armTemplate = Join-Path $TempPath ('{0}.template.json' -f $CurrentContext.Get('OctopusVMName'))
    Save-AzureRmVMImage -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -DestinationContainerName 'images' -VHDNamePrefix $CurrentContext.Get('OctopusVMName') -Overwrite -Path $armTemplate
    
    $savedVmImage = (Get-Content -Path $armTemplate | ConvertFrom-Json).resources.properties.storageprofile.osdisk.image.uri
    
    Write-Host 'Connecting to source storage account...'
    if ($savedVmImage -match 'http:\/\/(?<accountname>[a-zA-Z0-9]+)\.blob\.core\.windows\.net\/(?<containername>[a-zA-Z]+)\/(?<blobname>.+)') {
        $srcStorageAccount = $Matches['accountname']
        $srcContainer =  $Matches['containername']
        $srcBlob =  $Matches['blobname']
    } else {
        throw "Unable to identify VM Image storage account details from $savedVmImage"
    }
    $srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $srcStorageAccount)[0].Value)

    Write-Host 'Connecting to destination storage account...'
    $dstContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if(!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off
    }
    $dstBlob = '{0}.image.vhd' -f $CurrentContext.Get('OctopusVMName')

    Write-Host 'Copying VM Image to Stack Resources Storage Account...'
    
    Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob -DestContext $dstContext -DestContainer images -DestBlob $dstBlob

}