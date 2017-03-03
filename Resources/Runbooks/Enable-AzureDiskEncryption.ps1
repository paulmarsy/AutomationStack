param($Name)

Write-Output "Starting Enable-AzureDiskEncryption Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

.\Connect-AzureRm.ps1
$deploymentAsyncOperationUri = & .\Start-ResourceGroupDeployment.ps1 -Template diskEncryption -TemplateParameters @{
    name = $Name
}
.\Wait-ResourceGroupDeployment.ps1 -DeploymentAsyncOperationUri $deploymentAsyncOperationUri
Write-Output "Enable-AzureDiskEncryption Runbook completed successfully"