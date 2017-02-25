param($LogFileName)

$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

Write-Output 'Connecting to Azure Storage Account...'
$storageContainer = Get-AzureStorageContainer -Name 'scriptlogs' -ErrorAction Ignore
if (!$storageContainer) {
    $storageContainer = New-AzureStorageContainer -Name 'scriptlogs' -Permission Off
}
$logFileBlobRef = $storageContainer.CloudBlobContainer.GetAppendBlobReference($LogFileName)

Write-Output 'Waiting for script to connect...'
while (!$logFileBlobRef.Exists()) { Start-Sleep -Seconds 5 }
Write-Output 'Script connected, waiting...'
$logPosition = 0
$terminateSignaled = $false
do {
    Start-Sleep -Milliseconds 250
    $logFileBlobRef.DownloadText().Split([System.Environment]::NewLine) | ? { -not [string]::IsNullOrEmpty($_) } | Select-Object -Skip $logPosition | % { 
        $logPosition++
        if ($_.Trim() -eq 'SIGTERM') { $terminateSignaled = $true }
        $_ | Write-Output
    }
} while (!$terminateSignaled)
