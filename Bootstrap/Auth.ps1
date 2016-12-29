#Requires -Version 5.0
param(
    $AzureUsername,
    $AzurePassword,
    $SubscriptionId,
    $AzureRegion = 'West Europe' #'North Europe' - SQL Server isn't able to be provisioned in EUN currently
)

$confirmed = 1
while ($confirmed -ne 0) {
    Write-Host -ForegroundColor Magenta "Azure Authentication Details"
    if (!($AzureUsername)) { $AzureUsername = Read-Host -Prompt "Azure Username" } 
    if (!($AzurePassword)) { $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString }
    else { $securePassword = $AzurePassword | ConvertTo-SecureString -AsPlainText -Force }
    if (!($SubscriptionId)) { $SubscriptionId = Read-Host -Prompt "Azure Subscription ID" } 
    
    $confirmed = $Host.UI.PromptForChoice("Confirm", "AutomationStack will be created in Subscription ID $SubscriptionId with $AzureUsername credentials", ([System.Management.Automation.Host.ChoiceDescription[]]@(
        (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes")
        (New-Object System.Management.Automation.Host.ChoiceDescription "&No")
    )), 0)
}
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

Write-Host 'Proceeding to core infrastruction provisioning...'
& (Join-Path $PSScriptRoot 'Configure.ps1' -Resolve) -AzureRegion $AzureRegion