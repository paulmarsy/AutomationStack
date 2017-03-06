using namespace Microsoft.WindowsAzure.Commands.Common
using namespace Microsoft.IdentityModel.Clients.ActiveDirectory
using namespace Microsoft.Azure.Commands.Common.Authentication

param($ServicePrincipalCertificate, $ServicePrincipalClientId, $DeploymentAsyncOperationUri, $DeploymentName)

function Get-DeploymentResource {     
    param($ResourceGroupName, $DeploymentName)  
    Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName  | % properties | ? { $_.provisioningOperation -eq 'Create' } | % {
        [pscustomobject]@{
            Id = $_.targetResource.id
            DeploymentName = $DeploymentName
            ProvisioningState = $_.provisioningState
            Status = $_.statusCode
            Type = $_.targetResource.resourceType
            Name = $_.targetResource.resourceName
        }
        if ($_.targetResource.resourceType -eq 'Microsoft.Resources/deployments') {
            Get-DeploymentResource -ResourceGroupName $ResourceGroupName -DeploymentName $_.targetResource.resourceName
        }
    }
}
function Compare-DeploymentResources {
    param($Resources, $DeploymentName, $ResourceComparitor)
    $Resources | ? DeploymentName -eq $DeploymentName | % {
        $currentResourceStatus = @($_.ProvisioningState,$_.Status) -join '/'
        $previousResource = $ResourceComparitor | ? Id -eq $_.Id
        if ($previousResource) {
            $previousResourceStatus = @($previousResource.ProvisioningState,$previousResource.Status) -join '/'
        } else {
            $previousResourceStatus = 'New'
        }
        
        if ($_.ResourceType -eq 'Microsoft.Resources/deployments' -and $DeploymentName -ne $_.ResourceName -and $previousResourceStatus -ne 'New') {
            Compare-DeploymentResources -Resources $Resources -DeploymentName $_.ResourceName -ResourceComparitor $ResourceComparitor
        }
        if ($previousResourceStatus -ne $currentResourceStatus) {
            if ($_.Type -eq 'Microsoft.Resources/deployments') {
                if ($_.ProvisioningState -eq 'Succeeded') { $fg = @{ForegroundColor = [System.ConsoleColor]::Green} }
                elseif ($previousResourceStatus -eq 'New') {$fg = @{ForegroundColor = [System.ConsoleColor]::Blue} }
            } else {
                $fg = @{}
            }
            Write-Host @fg "$($_.Type)/$($_.Name) $previousResourceStatus -> $currentResourceStatus"
        }

        if ($_.Type -eq 'Microsoft.Resources/deployments' -and $DeploymentName -ne $_.ResourceName -and $previousResourceStatus -eq 'New') {
            Compare-DeploymentResources -Resources $Resources -DeploymentName $_.Name -ResourceComparitor $ResourceComparitor
        }
    }
}
function Get-DeploymentResourceState {  
    param($ResourceGroupName, $DeploymentName, $ResourceComparitor, $OperationJson)   
    $resources = @([pscustomobject]@{
            Id = $DeploymentName
            DeploymentName = $DeploymentName
            ProvisioningState = $OperationJson.status
            Status = 'Created'
            Type = 'Microsoft.Resources/deployments'
            Name = $DeploymentName
        })
    $resources += Get-DeploymentResource -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName
    Compare-DeploymentResources -Resources $resources -DeploymentName $DeploymentName -ResourceComparitor $ResourceComparitor

    return $resources
}

$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([System.Convert]::FromBase64String($ServicePrincipalCertificate))
$assertionClientCert = [ClientAssertionCertificate]::new($ServicePrincipalClientId, $cert)
$authContext = [AuthenticationContext]::new(([AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid), [TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken([Models.AzureEnvironmentConstants]::AzureServiceEndpoint, $assertionClientCert)

$response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
Write-Host $response.RawContent
$json = $response.Content | ConvertFrom-Json

do {
    $resources = Get-DeploymentResourceState -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName -ResourceComparitor $resources -OperationJson $json
    Start-Sleep 1
    $response = Invoke-WebRequest -Uri $DeploymentAsyncOperationUri -Headers @{ [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $accessToken.CreateAuthorizationHeader() }  -ContentType 'application/json' -UseBasicParsing
    $json = $response.Content | ConvertFrom-Json
} while ($json.Status -in @('Accepted','Running'))

if ($json.Status -eq 'Failed') {
    Write-Host ([regex]::Unescape(($json.error | Format-List | Out-String)))
    throw $json.error.message
} else {
    Write-Host $response.RawContent
}