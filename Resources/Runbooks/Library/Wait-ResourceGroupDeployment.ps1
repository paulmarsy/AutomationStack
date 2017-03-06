param($DeploymentAsyncOperationUri, $DeploymentName)

Write-Host "Starting Wait-ResourceGroupDeployment Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

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
        
        if ($_.Type -eq 'Microsoft.Resources/deployments' -and $DeploymentName -ne $_.Name -and $previousResourceStatus -ne 'New') {
            Compare-DeploymentResources -Resources $Resources -DeploymentName $_.Name -ResourceComparitor $ResourceComparitor
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

        if ($_.Type -eq 'Microsoft.Resources/deployments' -and $DeploymentName -ne $_.Name -and $previousResourceStatus -eq 'New') {
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

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
$ResourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
$assertionClientCert = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($ServicePrincipalConnection.ApplicationId, (Get-Item (Join-Path Cert:\CurrentUser\My $ServicePrincipalConnection.CertificateThumbprint)))
$authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new((([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint('ActiveDirectory')+[Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid)), [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)
$accessToken = $authContext.AcquireToken('https://management.core.windows.net/', $assertionClientCert)

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