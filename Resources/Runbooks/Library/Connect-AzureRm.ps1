Write-Output "Starting Connect-AzureRm Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Write-Output ("Authenticating with:`n{0}" -f ($ServicePrincipalConnection | Out-String | % Trim))
Add-AzureRmAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Out-Null
Write-Output 'Connected to Azure'
$ResourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName (Get-AutomationVariable -Name "StorageAccountName") | Out-Null
Write-Output 'Storage Account Context Set'
Write-Output ("AzureRm Context:`nResource Group: {0}`n{1}" -f $ResourceGroupName, (Get-AzureRmContext | Out-String | % Trim))