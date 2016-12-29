#Requires -Version 5.0
param(
    $AzureUsername,
    $AzurePassword,
    $SubscriptionId,
    $AzureRegion = 'North Europe'
)

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
if (Get-InstalledModule -Name AzureRM -ErrorAction Ignore) {
    Write-Host 'Importing Azure PowerShell Module...'
    Import-Module AzureRm -Force -Global
} else {
    Write-Host 'Installing Azure PowerShell Module...'
    Install-Module AzureRM
}

Write-Host -ForegroundColor Magenta "Azure Authentication"
if (!($AzureUsername)) { $AzureUsername = Read-Host -Prompt "Azure Username" } 
if (!($AzurePassword)) { $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString }
else { $securePassword = $AzurePassword | ConvertTo-SecureString -AsPlainText -Force }
if (!($SubscriptionId)) { $SubscriptionId = Read-Host -Prompt "Azure Subscription ID" } 

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

Write-Host 'Proceeding to core infrastruction provisioning...'
& (Join-Path $PSScriptRoot 'Configure.ps1' -Resolve) -AzureRegion $AzureRegion