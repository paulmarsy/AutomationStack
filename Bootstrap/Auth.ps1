#Requires -Version 5.0
param(
    $AzureUsername,
    $AzurePassword,
    $AzureRegion = 'West Europe' #'North Europe' - SQL Server isn't able to be provisioned in EUN currently
)

Write-Host -ForegroundColor Magenta "Azure Authentication Details"
if (!($AzureUsername)) { $AzureUsername = Read-Host -Prompt "Azure Username" } 
if (!($AzurePassword)) { $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString }
else { $securePassword = $AzurePassword | ConvertTo-SecureString -AsPlainText -Force }

Write-Host
if (Get-InstalledModule -Name AzureRM -ErrorAction Ignore) {
    Write-Host 'Importing Azure PowerShell Module...'
    Import-Module AzureRm -Force -Global
} else {
    Write-Host 'Installing Azure PowerShell Module...'
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module AzureRM
}
Write-Host
try {
    $credential = New-Object PSCredential($AzureUsername, $securePassword)
    Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline "Logging into Azure.. "
    $rmContext = Add-AzureRmAccount -Credential $credential -ErrorAction Stop -SubscriptionId $SubscriptionId
    Write-Host -ForegroundColor Green -BackgroundColor Black "Successful"
    $rmContext | Format-List | Out-Host
}
catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Failed ($($_.Exception.Message))"
    throw
}

& (Join-Path $PSScriptRoot '..\Utils\Set-AzureSubscriptionSelection.ps1')

Write-Host 'Proceeding to core infrastruction provisioning...'
& (Join-Path $PSScriptRoot 'Configure.ps1' -Resolve) -AzureRegion $AzureRegion