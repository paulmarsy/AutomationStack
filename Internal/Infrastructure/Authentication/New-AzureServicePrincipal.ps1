function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force | Out-Host
    
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris $CurrentContext.Eval('http://#{Name}.local') -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    $CurrentContext.Set('ServicePrincipalObjectId', $servicePrincipal.Id.Guid)

    do {
        Start-Sleep -Seconds 1
        $roleAssignment = New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId -ErrorAction Ignore
    } while (!$roleAssignment)
    $roleAssignment | Out-Host

    do {
        Start-Sleep -Seconds 1
        $appGet =  Get-AzureRmADApplication -ApplicationId $app.ApplicationId -ErrorAction Ignore
    } while (!$appGet)
    $appGet | Out-Host

    Start-Sleep -Seconds 5
    $CurrentContext.Set('ServicePrincipalCreated', $true)
}