param($LogFileName, $StorageAccountName, $StorageAccountKey)

Write-Host 'Connecting to Azure Storage Account...'
$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$storageContainer = Get-AzureStorageContainer -Name 'scriptlogs' -Context $context -ErrorAction SilentlyContinue
if (!$storageContainer) {
    $storageContainer = New-AzureStorageContainer -Name 'scriptlogs' -Context $context -Permission Off
}
$logFileBlobRef = $storageContainer.CloudBlobContainer.GetAppendBlobReference($LogFileName)

Write-Host 'Waiting for script to connect...'
while (!$logFileBlobRef.Exists()) { Start-Sleep -Seconds 5 }
Write-Host 'Script connected, waiting...'
$logPosition = 0
$terminateSignaled = $false
do {
    Start-Sleep -Milliseconds 250
    $logFileBlobRef.DownloadText().Split([System.Environment]::NewLine) | ? { -not [string]::IsNullOrEmpty($_) } | Select-Object -Skip $logPosition | % { 
        $logPosition++
        if ($_.Trim() -eq 'SIGTERM') { $terminateSignaled = $true }
        $_ | Out-Host
    }
} while (!$terminateSignaled)
