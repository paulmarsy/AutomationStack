function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force

    
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris "http://$($CurrentContext.Get('Name')).local" -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    $CurrentContext.Set('ServicePrincipalObjectId', $servicePrincipal.Id.Guid)

    Start-Sleep -Seconds 20
    
    New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ObjectId  $servicePrincipal.Id.Guid
    $CurrentContext.Set('ServicePrincipalCreated', $true)
}