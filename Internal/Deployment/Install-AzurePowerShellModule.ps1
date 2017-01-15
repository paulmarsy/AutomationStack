function Install-AzurePowerShellModule {
    Write-Host
    if (Get-InstalledModule -Name AzureRM -ErrorAction Ignore) {
        Write-Host 'Importing Azure PowerShell Module...'
        Import-Module AzureRm -Force -Global
    } else {
        Write-Host 'Installing Azure PowerShell Module...'
        Install-PackageProvider -Name NuGet -Force
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module AzureRM
    }
    Write-Host
}