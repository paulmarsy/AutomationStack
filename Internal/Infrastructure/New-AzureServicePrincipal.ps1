function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force | Out-Host
    
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris $CurrentContext.Eval('http://#{Name}.local') -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    $CurrentContext.Set('ServicePrincipalObjectId', $servicePrincipal.Id.Guid)

    Start-Sleep -Seconds 20
    New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName  $app.ApplicationId | Out-Host
    Start-Sleep -Seconds 20

    $CurrentContext.Set('ServicePrincipalCreated', $true)
}