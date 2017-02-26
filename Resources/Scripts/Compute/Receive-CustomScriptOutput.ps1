param($LogFileName)

Write-Host 'Connecting to Azure Storage Account...'
$storageContainer = Get-AzureStorageContainer -Name 'scriptlogs' -ErrorAction Ignore
if (!$storageContainer) {
    $storageContainer = New-AzureStorageContainer -Name 'scriptlogs' -Permission Off
}
$logFileBlobRef = $storageContainer.CloudBlobContainer.GetAppendBlobReference($LogFileName)

Write-Host 'Waiting for script to connect...'
while (!$logFileBlobRef.Exists()) { Start-Sleep -Seconds 5 }
Write-Host 'Script connected, waiting...'
$logPosition = 0
$terminateSignaled = $false
do {
    Start-Sleep -Milliseconds 100
    $logFileBlobRef.DownloadText().Split([System.Environment]::NewLine) | ? { -not [string]::IsNullOrEmpty($_) } | Select-Object -Skip $logPosition | % { 
        $logPosition++
        if ($_.Trim() -eq 'SIGTERM') { $terminateSignaled = $true }
        Write-Host $_
    }
} while (!$terminateSignaled)
