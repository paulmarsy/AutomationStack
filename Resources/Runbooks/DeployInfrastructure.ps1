Write-Output "Starting DeployInfrastructure Runbook..."
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Write-Output ($ServicePrincipalConnection | Out-String)
$azureRmContext = Add-AzureRmAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
Write-Output "Connected to AzureRm`nContext:"
Write-Output ($azureRmContext | Out-String)

$resourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
Write-Output "ResourceGroupName: $resourceGroupName"
$storageAccountName = Get-AutomationVariable -Name "StorageAccountName"
Write-Output "StorageAccountName: $storageAccountName"
$context = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

$runbookSasToken = New-AzureStorageContainerSASToken -Name runbooks -Permission r -ExpiryTime (Get-Date).AddHours(1) -Context $context
$runbooks = $context.StorageAccount.CreateCloudBlobClient().GetContainerReference('runbooks').ListBlobs() | % { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }

.\StartTemplateDeployment.ps1 -ServicePrincipalConnection $ServicePrincipalConnection -ResourceGroupName $resourceGroupName -Context $context -Template infrastructure -TemplateParameters @{
    runbookSasToken = $runbookSasToken
    runbooks = $runbooks
}