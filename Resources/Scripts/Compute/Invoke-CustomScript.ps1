param($Name, $ResourceGroupName, $VMName, $Location, $StorageAccountName, $StorageAccountKey)

Write-Host "Invoking AzureVM Custom Script $Name..."

Write-Host 'Connecting to Azure Storage Account...'
$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$storageContainer = Get-AzureStorageContainer -Name 'scriptlogs' -Context $context -ErrorAction SilentlyContinue
if (!$storageContainer) {
        $storageContainer = New-AzureStorageContainer -Name 'scriptlogs' -Context $context -Permission Off
}

$logFileName = '{0}.{1}.log' -f $Name, ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
$logFileBlobRef = $storageContainer.CloudBlobContainer.GetAppendBlobReference($logFileName)
$logFileBlobRef.CreateOrReplace()

Write-Host 'Starting custom script extension in background job...'
$azureProfile = [System.IO.Path]::GetTempFileName()
Save-AzureRmProfile -Path $azureProfile -Force

$ArgumentList = "-LogFileName $logFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey"

$job = Start-Job -ScriptBlock {
        param($SubscriptionId, $AzureProfile, $ResourceGroupName, $VMName, $Location, $Name, $StorageAccountName, $StorageAccountKey, $ContainerName, $Argument)
        $ErrorActionPreference = 'Stop'
        Select-AzureRmProfile -Profile $AzureProfile | Out-Null
        Remove-Item -Path $AzureProfile -Force | Out-Null
        Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null

        $scriptFileName = '{0}.ps1' -f $Name
        Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Location $Location -Name 'CustomScript' -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -FileName @($scriptFileName,'CustomScriptLogging.ps1') -ContainerName 'scripts' -Run $scriptFileName -ForceRerun (Get-Date).Ticks -SecureExecution -Argument $Argument
} -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureProfile, $ResourceGroupName, $VMName, $Location, $Name, $StorageAccountName, $StorageAccountKey, $ContainerName, $ArgumentList)

Write-Host 'Waiting for script to run...'
$logPosition = 0
do {
        Start-Sleep 1
        $logFileBlobRef.DownloadText().Split([System.Environment]::NewLine) | ? { -not [string]::IsNullOrEmpty($_) } | Select-Object -Skip $logPosition | % { $logPosition++; $_ | Out-Host }
} while ($job.State -eq 'Running')

if ($job.State -ne 'Completed') {
    Write-Warning "Job did not complete successfully, output:"
    $job | Receive-Job | Out-Host

}
Write-Host
$duration = $job.PSEndTime - $job.PSBeginTime
Write-Host ('AzureRM Custom Script Extension finished with state: {0} after {1} minutes, {2} seconds' -f $job.State, $duration.Minutes, $duration.Seconds)
$job | Remove-Job
