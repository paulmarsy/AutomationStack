function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force

    Add-Type -AssemblyName System.Web
    $servicePrincipalPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)
    
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris "http://$($CurrentContext.Get('Name')).local" -Password $servicePrincipalPassword
    
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    $CurrentContext.Set('ServicePrincipalClientSecret', $servicePrincipalPassword)
    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    $CurrentContext.Set('ServicePrincipalObjectId', $servicePrincipal.Id.Guid)

    Start-Sleep -Seconds 20
    
    New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName  $app.ApplicationId
}