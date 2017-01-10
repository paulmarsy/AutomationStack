function Restore-AzureRmAuthContext { 
    $azureRmProfilePath = Join-Path $TempPath 'AzureRmProfile.json'
    if (Test-Path $azureRmProfilePath) {
        Write-Host -NoNewLine 'Restoring original Azure context...'
        Select-AzureRmProfile -Path $azureRmProfilePath | Out-Null
        Remove-Item -Path $azureRmProfilePath -Force
        Write-Host 'done'
    }
}