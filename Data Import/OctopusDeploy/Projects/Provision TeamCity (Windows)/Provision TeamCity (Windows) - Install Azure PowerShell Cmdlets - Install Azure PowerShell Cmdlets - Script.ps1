if ($OctopusParameters['Octopus.Action.Azure.UseBundledAzurePowerShellModules'] -ne 'False') {
    throw 'Octopus.Action.Azure.UseBundledAzurePowerShellModules variable must be set to false'
}
if (Get-Module -ListAvailable -Name AzureRm) {
    return
}

New-Item -Path "$env:APPDATA\Windows Azure Powershell" -Type Directory -Force | Out-Null
Set-Content -Path "$env:APPDATA\Windows Azure Powershell\AzureDataCollectionProfile.json" -Value '{"enableAzureDataCollection":false}'

Install-PackageProvider -Name NuGet -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module AzureRm -Force