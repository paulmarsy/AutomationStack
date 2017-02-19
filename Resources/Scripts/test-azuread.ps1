filter Out-Object {
  $_ | Format-List * -Force | Out-String | % Trim | % Split "`n" | % { "`t" + $_ }   
}

'ADAL UserInfo:'
$authority = (@([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ActiveDirectory),
                [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid) -join '')
$authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority, [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)
$accesstoken = $authContext.AcquireToken([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironmentConstants]::AzureServiceEndpoint, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellRedirectUri)
$accesstoken.UserInfo | Out-Object

'Context Account:'
Get-AzureRmContext | % Account | Out-Object

$userId = Get-AzureRmContext | % Account | % Id
"Context User Id: $userId"
$accIdCount = (Get-AzureRmContext | % Account | % Id).Count
"Found: $accIdCount"

'AzureAd User (UPN - should pass):'
try {
    $user = Get-AzureRmADUser -UserPrincipalName $userId
    $user | Out-Object
    'via ObjectId Guid'
    Get-AzureRmADUser -ObjectId $user.Id.Guid | Out-Object
}
catch { "`t" + $_.Exception.Message }

'AzureAd User (ObjectId - should fail):'
try {
    $user = Get-AzureRmADUser -ObjectId $userId | Out-Object
    $user | Out-Object
    'via ObjectId Guid'
    Get-AzureRmADUser -ObjectId $user.Id.Guid | Out-Object
}
catch { "`t" + $_.Exception.Message }