function Restore-AzureRmAuthContext { 
    Write-Host
    $azureRmProfilePath = Join-Path $TempPath 'AzureRmProfile.json'
    if (Test-Path $azureRmProfilePath) {
        Write-Host -NoNewLine 'Restoring original Azure authentication context...'
        Select-AzureRmProfile -Path $azureRmProfilePath | Out-Null
        Remove-Item -Path $azureRmProfilePath -Force
        Write-Host 'done'
    }
}