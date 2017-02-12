param($LogFileName, $StorageAccountName, $StorageAccountKey, $ContainerName = 'scriptlogs')

if (!(Get-Module -ListAvailable -Name Azure.Storage)) {
    New-Item -Path "$env:APPDATA\Windows Azure Powershell" -Type Directory | Out-Null
    Set-Content -Path "$env:APPDATA\Windows Azure Powershell\AzureDataCollectionProfile.json" -Value '{"enableAzureDataCollection":false}'

    Install-PackageProvider -Name NuGet -Force | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-Null
    Install-Module Azure.Storage -Force  -WarningAction Ignore
}
Import-Module Azure.Storage -Force -Global
if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$storageContainer = Get-AzureStorageContainer -Name 'scriptlogs' -Context $context -ErrorAction SilentlyContinue
if (!$storageContainer) {
    $storageContainer = New-AzureStorageContainer -Name 'scriptlogs' -Context $context -Permission Off
}

$logFileBlobRef = $storageContainer.CloudBlobContainer.GetAppendBlobReference($logFileName)
$logFileBlobRef.CreateOrReplace()

$script:logFilePath = "C:\CustomScriptLogs\$LogFileName"

function Send-SignalTerminate {
    'SIGTERM' | Out-File -FilePath $logFilePath -Append 
    $logFileBlobRef.AppendText('SIGTERM')
}
filter Write-Log {
    $entry = '[{0}] {1}: {2}' -f $env:COMPUTERNAME, (Get-Date).ToShortTimeString(), ($_ | Out-String)
    $entry | Out-File -FilePath $logFilePath -Append 
    $logFileBlobRef.AppendText($entry)
}

$script:ErrorActionPreference = 'Stop'

"{0}[ Azure VM Custom Script Starting ]{0}" -f ("-"*32) | Write-Log
