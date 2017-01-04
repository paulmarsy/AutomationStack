function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris "http://$($CurrentContext.Get('Name')).local" -Password $CurrentContext.Get('Password')
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    Start-Sleep -Seconds 20
    New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName  $app.ApplicationId
}