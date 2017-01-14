param($ResourceGroupName, $VMName, $NodeName)

    Write-Host 'Stopping VM... '
    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force | Out-Host

    Write-Host 'Generalizing VM... '
    Set-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Generalized | Out-Host

    Write-Host 'Saving VM Image... '
]    $armTemplate = [System.IO.Path]::GetTempFileName()

    Save-AzureRmVMImage -ResourceGroupName $ResourceGroupName -Name $VMName -DestinationContainerName 'images' -VHDNamePrefix $VMName -Overwrite -Path $armTemplate | Out-Host
    $savedVmImage = (Get-Content -Path $armTemplate | ConvertFrom-Json).resources.properties.storageprofile.osdisk.image.uri
