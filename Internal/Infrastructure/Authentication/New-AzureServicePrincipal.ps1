function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force | Out-Null
    
    $servicePrincipal = New-AzureRmADServicePrincipal -DisplayName $CurrentContext.Get('Name')
    $CurrentContext.Set('ServicePrincipalClientId', $servicePrincipal.ApplicationId)
    $spObjectId = $servicePrincipal.Id.Guid
    $CurrentContext.Set('ServicePrincipalObjectId', $spObjectId)

    do {
        Start-Sleep -Seconds 5
        New-AzureRmRoleAssignment -ObjectId $spObjectId -RoleDefinitionName Contributor -Scope $CurrentContext.Eval('/subscriptions/#{AzureSubscriptionId}') -ErrorAction Ignore | Out-Host
        $roleAssignment = Get-AzureRmRoleAssignment -ObjectId $spObjectId -ErrorAction Ignore
    } while (!$roleAssignment)

    New-AzureRmADAppCredential -ObjectId $spObjectId -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $cert = New-SelfSignedCertificateEx -Subject "CN={#UDP}, O=AutomationStack" -KeySpec Exchange -FriendlyName $CurrentContext.Get('Name')
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
    $CurrentContext.Set('ServicePrincipalCertificate', $keyValue)
    $CurrentContext.Set('ServicePrincipalCertificateThumbprint', $cert.Thumbprint)
    New-AzureRmADAppCredential -ObjectId $spObjectId -CertValue $keyValue -StartDate $cert.GetEffectiveDateString() -EndDate $cert.GetExpirationDateString()
    Remove-Item (Join-Path 'Cert:\CurrentUser\My\' $cert.Thumbprint)

    Start-Sleep -Seconds 5

    $CurrentContext.Set('ServicePrincipalCreated', $true)
}