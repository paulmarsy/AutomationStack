function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
        
    $servicePrincipal = New-AzureRmADServicePrincipal -DisplayName $CurrentContext.Get('Name')
    $CurrentContext.Set('ServicePrincipalClientId', $servicePrincipal.ApplicationId)
    $spObjectId = $servicePrincipal.Id.Guid
    $CurrentContext.Set('ServicePrincipalObjectId', $spObjectId)

    New-AzureRmADSpCredential -ObjectId $spObjectId -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $cert = New-SelfSignedCertificateEx -Subject $CurrentContext.Eval('CN=#{UDP}, O=AutomationStack') -FriendlyName $CurrentContext.Get('Name')
    $CurrentContext.Set('ServicePrincipalCertificate', $cert.Base64Pfx)
    $CurrentContext.Set('ServicePrincipalCertificateThumbprint', $cert.Thumbprint)
    New-AzureRmADSpCredential -ObjectId $spObjectId -CertValue $keyValue -StartDate $cert.GetEffectiveDateString() -EndDate $cert.GetExpirationDateString()

    do {
        try { New-AzureRmRoleAssignment -ServicePrincipalName $servicePrincipal.ApplicationId -RoleDefinitionName Contributor -Scope $CurrentContext.Eval('/subscriptions/#{AzureSubscriptionId}') -ErrorAction Stop | Out-Host; $assigned = $true }
        catch { Start-Sleep -Seconds 1 }
    } while (!$assigned)

    $CurrentContext.Set('ServicePrincipalCreated', $true)
}