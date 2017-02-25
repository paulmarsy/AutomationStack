param($ServicePrincipalConnection, $ResourceGroupName, $Template, $TemplateParameters)

Write-Output "Starting StartTemplateDeployment Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$clientCertificate = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($ServicePrincipalConnection.ApplicationId, (Get-Item (Join-Path Cert:\CurrentUser\My $ServicePrincipalConnection.CertificateThumbprint)))
$accessToken = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new(
    (@([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory'),
       [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid) -join ''),
       [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared).AcquireToken('https://management.core.windows.net/', $clientCertificate)
Write-Output ("ARM Deployment Authentication:`n{0}" -f ($accessToken | Out-String | % Trim))

$uri = '{0}subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.Resources/deployments/{3}?api-version=2016-09-01'-f `
    [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ResourceManager'),    
    [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Subscription.Id,
    $ResourceGroupName,
    $Template
Write-Output "Deployment Uri: $uri"

$parameters= @{
    templateSasToken = @{
        value = [string](New-AzureStorageContainerSASToken -Name arm -Permission r -ExpiryTime (Get-Date).AddHours(1))
    }
}
$TemplateParameters.GetEnumerator() | % { $parameters += @{ ([string]$_.Key) = @{ value = $_.Value.psobject.baseobject } } }

$body = [Newtonsoft.Json.JsonConvert]::SerializeObject((@{
  properties = @{
    templateLink = @{
      uri = [string](New-AzureStorageBlobSASToken -Container arm -Blob "${Template}.json" -Permission r -ExpiryTime (Get-Date).AddHours(1) -FullUri)
    }
    mode = 'Incremental'
    parameters = $parameters
  }
}), [Newtonsoft.Json.JsonSerializerSettings]@{Formatting=[Newtonsoft.Json.Formatting]::Indented})
Write-Output "Deployment Request:`n$body`n"

Write-Output 'Submitting deployment...'
$request = Invoke-WebRequest -Uri $uri -Method Put -Body $body -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Output "Deployment Response:`n$($request.RawContent)`n"

$deployAsyncOperationUri = $request.Headers['Azure-AsyncOperation']
$response = Invoke-WebRequest -Uri $deployAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Output $response.RawContent
 
while (($response.Content | ConvertFrom-Json).Status -notin @('Failed','Succeeded')) {
    Start-Sleep -Seconds 10
    $response = Invoke-WebRequest -Uri $deployAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    [pscustomobject]@{
        Date = $response.Headers['Date']
        Status = "$($response.StatusCode) $($response.StatusDescription)"
        Content = $response.Content
    } | Format-List | Out-String | Write-Output
}