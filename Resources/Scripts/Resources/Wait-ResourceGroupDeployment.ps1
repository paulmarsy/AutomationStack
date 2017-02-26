using namespace Microsoft.WindowsAzure.Commands.Common
using namespace Microsoft.IdentityModel.Clients.ActiveDirectory
using namespace Microsoft.Azure.Commands.Common.Authentication

param($DeploymentAsyncOperationUri)

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
$authContext = [AuthenticationContext]::new(([AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid), [TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken([Models.AzureEnvironmentConstants]::AzureServiceEndpoint, [AdalConfiguration]::PowerShellClientId, [AdalConfiguration]::PowerShellRedirectUri)

$response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Host $response.RawContent
Write-StatusUpdate $response -WithHeader

while ($json.Status -in @('Accepted','Running')) {
    Start-Sleep -Seconds 10
    $response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    Write-StatusUpdate $response
    $json = $response.Content | ConvertFrom-Json
} 
if ($json.Status -eq 'Failed') {
    Write-Host ([regex]::Unescape(($json.error | Format-List | Out-String)))
} else {
    Write-Host $response.RawContent
}