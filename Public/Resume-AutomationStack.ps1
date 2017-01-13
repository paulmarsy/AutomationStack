function Resume-AutomationStack {
    Write-Host 'Creating VM storage account...'
    $storageAccountDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.image.storageaccount' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
    }

    Write-Host 'Connecting to source storage account... '
    $srcContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
    $srcContainer = 'images'
    $srcBlob = '{0}.image.vhd' -f $CurrentContext.Get('OctopusVMName')

    Write-Host 'Connecting to destination storage account... '
    $dstContext = New-AzureStorageContext -StorageAccountName $storageAccountDeploy.storageAccountName.Value -StorageAccountKey ((Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $storageAccountDeploy.storageAccountName.Value)[0].Value)
    $dstContainer = Get-AzureStorageContainer -Name images -Context $dstContext -ErrorAction SilentlyContinue
    if(!$dstContainer) {
        $dstContainer = New-AzureStorageContainer -Name images -Context $dstContext -Permission Off
    }
    $dstBlob = '{0}.image.vhd' -f $CurrentContext.Get('OctopusVMName')
    
    Write-Host 'Copying VM Image from Stack Resources Storage Account... '
    $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob -DestContext $dstContext -DestContainer images -DestBlob $dstBlob -Force
    $copyBlob | Get-AzureStorageBlobCopyState -WaitForComplete

    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.image' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        infraResourceGroup = $CurrentContext.Get('InfraRg')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('StackAdminUsername')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
        registrationUrl = $CurrentContext.Get('AutomationRegistrationUrl')
        nodeConfigurationName = 'OctopusDeploy.Server'
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        keyVaultResourceID = '/subscriptions/2da2b5d4-44d5-4263-848e-1db841c6ad11/resourceGroups/AutomationStack4ded/providers/Microsoft.KeyVault/vaults/keyvault4ded'
        vmImageUri = ('https://{0}.blob.core.windows.net/images/{1}.image.vhd' -f $storageAccountDeploy.storageAccountName.Value, $CurrentContext.Get('OctopusVMName'))
    } | Out-Null
    <#
OS Provisioning for VM 'OctopusVM' did not finish in the allotted time. However, the VM guest agent was detected running. This suggests the guest OS has not been properly prepared to be used as a VM image (with CreateOption=FromImage). To resolve this issue, either use the VHD as is with CreateOption=Attach or prepare it properly for use as an image

    #>
}