using namespace Microsoft.WindowsAzure.Commands.Common
using namespace Microsoft.IdentityModel.Clients.ActiveDirectory
using namespace Microsoft.Azure.Commands.Common.Authentication

param($ServicePrincipalCertificate, $ServicePrincipalClientId, $ResourceGroupName, $Template, $TemplateParameters)

$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([System.Convert]::FromBase64String($ServicePrincipalCertificate))
$assertionClientCert = [ClientAssertionCertificate]::new($ServicePrincipalClientId, $cert)
$authContext = [AuthenticationContext]::new(([AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid), [TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken([Models.AzureEnvironmentConstants]::AzureServiceEndpoint, $assertionClientCert)
Write-Host ("Deployment Authentication:`n{0}" -f ($assertionClientCert | Format-List | Out-String | % Trim))

$uri = '{0}{1}?api-version=2016-09-01'-f `
        [AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ResourceManager'),    
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetResourceId([AzureRmProfileProvider]::Instance.Profile.Context.Subscription.Id, $ResourceGroupName, 'Microsoft.Resources/deployments', $Template)
Write-Host "Deployment Uri: $uri"

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
Write-Host "Deployment Request:`n$body`n"

Write-Host 'Submitting deployment...'
$request = Invoke-WebRequest -Uri $uri -Method Put -Body $body -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Host "Deployment Response:`n$($request.RawContent)`n"

return $request.Headers['Azure-AsyncOperation']
$deployAsyncOperationUri = 
$response = Invoke-WebRequest -Uri $deployAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Host $response.RawContent
 
while (($response.Content | ConvertFrom-Json).Status -notin @('Failed','Succeeded')) {
    Start-Sleep -Seconds 10
    $response = Invoke-WebRequest -Uri $deployAsyncOperationUri -Headers @{ [ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    [pscustomobject]@{
        Date = $response.Headers['Date']
        Status = "$($response.StatusCode) $($response.StatusDescription)"
        Content = $response.Content
    } | Format-List | Out-String | Write-Host
}