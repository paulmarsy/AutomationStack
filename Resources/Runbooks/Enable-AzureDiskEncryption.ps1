param($Name)

Write-Host "Starting Enable-AzureDiskEncryption Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

.\Connect-AzureRm.ps1
$deploymentAsyncOperationUri = & .\Start-ResourceGroupDeployment.ps1 -Template diskEncryption -TemplateParameters @{
    name = $Name
}
.\Wait-ResourceGroupDeployment.ps1 -DeploymentAsyncOperationUri $deploymentAsyncOperationUri -DeploymentName diskEncryption
Write-Host "Enable-AzureDiskEncryption Runbook completed successfully"