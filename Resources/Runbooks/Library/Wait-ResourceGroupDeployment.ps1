param([uri]$DeploymentAsyncOperationUri)

Write-Output "Starting Wait-ResourceGroupDeployment Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Write-StatusUpdate {
    param($Response,[switch]$WithHeader)

    $showHeader = if ($WithHeader) {$false} else {$true}
    $entry = [pscustomobject]@{
        Date = $response.Headers['Date']
        Status = $Response.RawContent.Split([System.Environment]::NewLine)[0]
        Content = $Response.Content
    } | Format-Table -HideTableHeaders:$showHeader -Property @(
        @{Label = 'Date';Expression = {$_.Date}; Width=30},
        @{Label = 'Status';Expression = {$_.Status}; Width=20},
        @{Label = 'Content';Expression = {$_.Content}}
    ) | Out-String | % Trim
    
    Write-Output $entry
}

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
$assertionClientCert = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($ServicePrincipalConnection.ApplicationId, (Get-Item (Join-Path Cert:\CurrentUser\My $ServicePrincipalConnection.CertificateThumbprint)))
$authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new((([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid)), [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken('https://management.core.windows.net/', $assertionClientCert)

$response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Output $response.RawContent
$json = $response.Content | ConvertFrom-Json
Write-StatusUpdate $response -WithHeader

while ($json.Status -in @('Accepted','Running')) {
    Start-Sleep -Seconds 30
    $response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    Write-StatusUpdate $response
    $json = $response.Content | ConvertFrom-Json
} 
if ($json.Status -eq 'Failed') {
    Write-Output ([regex]::Unescape(($json.error | Format-List | Out-String)))
    throw $json.error.message
} else {
    Write-Output $response.RawContent
}