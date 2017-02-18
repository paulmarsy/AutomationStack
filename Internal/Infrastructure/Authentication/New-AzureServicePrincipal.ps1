function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
        
    $servicePrincipal = New-AzureRmADServicePrincipal -DisplayName $CurrentContext.Get('Name')
    $CurrentContext.Set('ServicePrincipalClientId', $servicePrincipal.ApplicationId)
    $spObjectId = $servicePrincipal.Id.Guid
    $CurrentContext.Set('ServicePrincipalObjectId', $spObjectId)

    New-AzureRmADSpCredential -ObjectId $spObjectId -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $cert = New-SelfSignedCertificateEx -Subject "CN={#UDP}, O=AutomationStack" -KeySpec Exchange -FriendlyName $CurrentContext.Get('Name') -Exportable
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
    $CurrentContext.Set('ServicePrincipalCertificate', $keyValue)
    $CurrentContext.Set('ServicePrincipalCertificateThumbprint', $cert.Thumbprint)
    New-AzureRmADSpCredential -ObjectId $spObjectId -CertValue $keyValue -StartDate $cert.GetEffectiveDateString() -EndDate $cert.GetExpirationDateString()
    Remove-Item (Join-Path 'Cert:\CurrentUser\My\' $cert.Thumbprint)

    do {
        try { New-AzureRmRoleAssignment -ServicePrincipalName $servicePrincipal.ApplicationId -RoleDefinitionName Contributor -Scope $CurrentContext.Eval('/subscriptions/#{AzureSubscriptionId}') -ErrorAction Stop | Out-Host; $assigned = $true }
        catch { Start-Sleep -Seconds 1 }
    } while (!$assigned)

    $CurrentContext.Set('ServicePrincipalCreated', $true)
}