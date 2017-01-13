function Suspend-AutomationStack {
    $script:start = [datetime](Get-Date)
    function Show-Duration {
        $timespan = ([datetime](Get-Date)) - $script:start
        Write-Host ([Humanizer.TimeSpanHumanizeExtensions]::Humanize($timespan, 2))
        $script:start = [datetime](Get-Date)
    }
    Write-Host -NoNewLine 'Stopping VM... '
#Stop-AzureRmVM -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -Force | Write-Verbose
    Show-Duration

    Write-Host -NoNewLine  'Generalizing VM... '
    Set-AzureRmVM -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -Generalized | Write-Verbose
    Show-Duration

    Write-Host -NoNewLine  'Saving VM Image... '
    $armTemplate = Join-Path $TempPath ('{0}.template.json' -f $CurrentContext.Get('OctopusVMName'))
    Save-AzureRmVMImage -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName') -DestinationContainerName 'images' -VHDNamePrefix $CurrentContext.Get('OctopusVMName') -Overwrite -Path $armTemplate | Write-Verbose
    $savedVmImage = (Get-Content -Path $armTemplate | ConvertFrom-Json).resources.properties.storageprofile.osdisk.image.uri
    Show-Duration
    
    Write-Host -NoNewLine  'Connecting to source storage account... '
    if ($savedVmImage -match 'http:\/\/(?<accountname>[a-zA-Z0-9]+)\.blob\.core\.windows\.net\/(?<containername>[a-zA-Z]+)\/(?<blobname>.+)') {
        $srcStorageAccount = $Matches['accountname']
        $srcContainer =  $Matches['containername']
        $srcBlob =  $Matches['blobname']
    } else {
        throw "Unable to identify VM Image storage account details from $savedVmImage"
    }
    $srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $srcStorageAccount)[0].Value)
    Show-Duration
    
    Write-Host -NoNewLine  'Connecting to destination storage account... '
    $dstContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if(!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off
    }
    $dstBlob = '{0}.image.vhd' -f $CurrentContext.Get('OctopusVMName')
    Show-Duration
    
    Write-Host -NoNewLine  'Copying VM Image to Stack Resources Storage Account... '
    $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob -DestContext $dstContext -DestContainer images -DestBlob $dstBlob -Force
    $copyBlob | Get-AzureStorageBlobCopyState -WaitForComplete
    Show-Duration
    
    Write-Host -NoNewLine   'Removing VM Resource Group... '
    Remove-AzureRmResourceGroup -Name $CurrentContext.Get('OctopusRg') -Force | Write-Verbose
    Show-Duration
}