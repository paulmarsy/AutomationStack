function Restore-AzureRmAuthContext { 
    param([switch]$Silent)
    $azureRmProfilePath = Join-Path $TempPath 'AzureRmProfile.json'
    if (Test-Path $azureRmProfilePath) {
        if (!$Silent) {
            Write-Host
            Write-Host -NoNewLine 'Restoring original Azure authentication context...'
        }
        Select-AzureRmProfile -Path $azureRmProfilePath | Out-Null
        Remove-Item -Path $azureRmProfilePath -Force
        if (!$Silent) {
            Write-Host 'done'
        }
    }
}