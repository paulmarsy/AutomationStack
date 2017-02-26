using namespace Microsoft.WindowsAzure.Commands.Common
using namespace Microsoft.IdentityModel.Clients.ActiveDirectory
using namespace Microsoft.Azure.Commands.Common.Authentication

param($ServicePrincipalCertificate, $ServicePrincipalClientId, $DeploymentAsyncOperationUri)

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
    
    Write-Host $entry
}

$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([System.Convert]::FromBase64String($ServicePrincipalCertificate))
$assertionClientCert = [ClientAssertionCertificate]::new($ServicePrincipalClientId, $cert)
$authContext = [AuthenticationContext]::new(([AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid), [TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken([Models.AzureEnvironmentConstants]::AzureServiceEndpoint, $assertionClientCert)

$response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Host $response.RawContent
$json = $response.Content | ConvertFrom-Json
Write-StatusUpdate $response -WithHeader

while ($json.Status -in @('Accepted','Running')) {
    Start-Sleep -Seconds 30
    $response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    Write-StatusUpdate $response
    $json = $response.Content | ConvertFrom-Json
} 
if ($json.Status -eq 'Failed') {
    Write-Host ([regex]::Unescape(($json.error | Format-List | Out-String)))
    throw $json.error.message
} else {
    Write-Host $response.RawContent
}