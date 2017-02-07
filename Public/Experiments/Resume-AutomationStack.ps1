function Resume-AutomationStack {
    $rg = $CurrentContext.Get('OctopusRg')
    $vmName = $CurrentContext.Get('OctopusVMName')

    Write-Host 'Generating ARM template... ' -NoNewLine

    $template = Get-Content -Path ([System.IO.Path]::Combine($ResourcesPath, 'ARM Templates', 'appserver.json')) | ConvertFrom-Json

    # Add appserver.enableencryption.json template
    $template.parameters | Add-Member -MemberType NoteProperty -Name 'keyVaultResourceID' -Value (New-Object PSCustomObject -Property @{ type = 'string' })
    $template.parameters | Add-Member -MemberType NoteProperty -Name 'keyVaultSecretUrl' -Value (New-Object PSCustomObject -Property @{ type = 'string' })
    $vmResource = $template.resources | ? type -eq 'Microsoft.Compute/virtualMachines'
    $vmResource.properties.storageProfile.osDisk | Add-Member -MemberType NoteProperty -Name 'encryptionSettings' -Value (New-Object PSCustomObject -Property @{
        diskEncryptionKey = (New-Object PSCustomObject -Property @{
            secretUrl = "[parameters('keyVaultSecretUrl')]"
            sourceVault = (New-Object PSCustomObject -Property @{ id = "[parameters('keyVaultResourceID')]" })
        })
    })
  #        "osType": "Windows",

    # Reuse existing VHD rather than provision from existing image
    $vmResource.properties.psobject.Properties.Remove('osProfile')
    $vmResource.properties.storageProfile.psobject.Properties.Remove('imageReference')
    $vmResource.properties.storageProfile.osDisk.createOption = 'Attach'


    $template | ConvertTo-Json -Depth 100 | Repair-Json | Out-File -FilePath (Join-Path $ResourcesPath 'ARM Templates\appserver.resume.json') -Force 
    Copy-Item -Path  (Join-Path $ResourcesPath 'ARM Templates\appserver.parameters.json') -Destination  (Join-Path $ResourcesPath 'ARM Templates\appserver.resume.parameters.json')
    Write-Host 'created' -ForegroundColor Green

        $storageDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.storage' -Mode Complete -TemplateParameters @{
            udp = $CurrentContext.Get('UDP')
        }

    Write-Host 'Connecting to storage accounts... ' -NoNewLine
        $srcContext = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
        $dstStorageAccountName = Get-AzureRmStorageAccount -ResourceGroupName $rg | % StorageAccountName
        $dstStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rg -Name $dstStorageAccountName)[0].Value
        $dstContext = New-AzureStorageContext -StorageAccountName $dstStorageAccountName -StorageAccountKey $dstStorageAccountKey
        $dstContainer = Get-AzureStorageContainer -Name vhds -Context $dstContext -ErrorAction SilentlyContinue
        if (!$dstContainer) {
            New-AzureStorageContainer -Name vhds -Context $dstContext -Permission Off | Out-Null
        }
        Write-Host 'connected' -ForegroundColor Green


        $blobName = 'OctopusVM-OS.vhd'
        Write-Host "Copying $blobName from $($srcContext.StorageAccountName) to $($dstContext.StorageAccountName)... "
        $copyBlob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer images -SrcBlob $blobName -DestContext $dstContext -DestContainer vhds -DestBlob $blobName -Force -Verbose
        while ($copyState.Status -ne "Success")
        {  
            Start-Sleep -Seconds 5
            $copyState = $copyBlob | Get-AzureStorageBlobCopyState
            $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
            Write-Host "Completed $('{0:N2}' -f $percent)%"
            Write-Progress -Activity "Copying $blobName from $($srcContext.StorageAccountName) to $($dstContext.StorageAccountName)" -CurrentOperation "$($copyState.Status) $('{0:N2}' -f $percent)% $percent" -PercentComplete $percent
        }

    $octopusDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.resume' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        infraResourceGroup = $CurrentContext.Get('InfraRg')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('StackAdminUsername')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $CurrentContext.Get('OctopusDiskEncryptionKeyUrl')
        registrationUrl = $CurrentContext.Get('AutomationRegistrationUrl')
        nodeConfigurationName = 'OctopusDeploy.Server'
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
    }
}