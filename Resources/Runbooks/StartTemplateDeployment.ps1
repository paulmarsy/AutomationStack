param($ServicePrincipalConnection, $ResourceGroupName, $Context, $Template, $TemplateParameters)

Write-Output "Starting StartTemplateDeployment Runbook..."
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$clientCertificate = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($ServicePrincipalConnection.ApplicationId, (Get-Item (Join-Path Cert:\CurrentUser\My $ServicePrincipalConnection.CertificateThumbprint)))
$accessToken = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new(
    (@([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory'),
       [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid) -join ''),
       [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared).AcquireToken('https://management.core.windows.net/', $clientCertificate)
Write-Output "ARM Deployment Authentication:"
Write-Output ($accessToken | Out-String)

$uri = '{0}subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.Resources/deployments/{3}?api-version=2016-09-01'-f `
    [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ResourceManager'),    
    [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Subscription.Id,
    $ResourceGroupName,
    $Template
Write-Output "ARM Deployment Uri: $uri"

$parameters= @{
    templateSasToken = @{
        value = (New-AzureStorageContainerSASToken -Name arm -Permission r -ExpiryTime (Get-Date).AddHours(1) -Context $Context)
    }
}
$TemplateParameters.GetEnumerator() | % { $parameters += @{ $_.Key = @{ value = $_.Value } } }

$body = (@{
  properties = @{
    templateLink = @{
      uri = (New-AzureStorageBlobSASToken -Container arm -Blob "${Template}.json" -Permission r -ExpiryTime (Get-Date).AddHours(1) -FullUri -Context $Context)
    }
    mode = 'Incremental'
    parameters = $parameters
  }
} | ConvertTo-Json -Depth 5) 

Write-Output "ARM Deployment Request: $body`n"
Write-Output 'Submitting deployment...'

$response = Invoke-WebRequest -Uri $uri -Method Put -Body $body -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Output ($response | Out-String)
$deployAsyncOperationUri = $response.Headers['Azure-AsyncOperation']
do {
    Start-Sleep -Seconds 20
    $response = Invoke-WebRequest -Uri $deployAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    Write-Output $response.RawContent
} while (($response.Content | ConvertFrom-Json).Status -notin @('Failed','Succeeded'))