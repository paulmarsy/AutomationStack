param($ResourceGroupName, $VMName)

do {
    Write-Host 'Waiting for VM Shutdown... '
    Start-Sleep -Seconds 5
    $state = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status | % Statuses | ? Code -like 'PowerState/*' | % DisplayStatus
} while ($state -ne 'VM stopped')

Write-Host 'Stopping VM... '
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force | Out-Host

Write-Host 'Generalizing VM... '
Set-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Generalized | Out-Host

Write-Host 'Saving VM Image... '
$armTemplate = [System.IO.Path]::GetTempFileName()

Save-AzureRmVMImage -ResourceGroupName $ResourceGroupName -Name $VMName -DestinationContainerName 'images' -VHDNamePrefix $VMName -Overwrite -Path $armTemplate | Out-Host
$savedVmImage = (Get-Content -Path $armTemplate | ConvertFrom-Json).resources.properties.storageprofile.osdisk.image.uri

Set-OctopusVariable "ImageUri" $savedVmImage

Remove-Item $armTemplate -Force