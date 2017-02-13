function New-AzureServicePrincipal {
    Write-Host 'Creating Azure Service Principal...'
    
    Get-AzureRmADApplication -DisplayNameStartWith $CurrentContext.Get('Name') | Remove-AzureRmADApplication -Force | Out-Host
    
    $app = New-AzureRmADApplication -DisplayName $CurrentContext.Get('Name') -IdentifierUris $CurrentContext.Eval('http://#{Name}.local') -Password $CurrentContext.Get('ServicePrincipalClientSecret')
    
    $CurrentContext.Set('ServicePrincipalClientId', $app.ApplicationId)
    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
    $CurrentContext.Set('ServicePrincipalObjectId', $servicePrincipal.Id.Guid)

    do {
        try {
            $roleAssignment = New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId
        }
        catch { Start-Sleep -Seconds 1 }
    } while (!$roleAssignment)
    $roleAssignment | Out-Host

    do {
        try {
            $appGet =  Get-AzureRmADApplication -ApplicationId $app.ApplicationId
        }
        catch { Start-Sleep -Seconds 1 }
    } while (!$appGet)
    $appGet | Out-Host

    Start-Sleep -Seconds 5
    
    $CurrentContext.Set('ServicePrincipalCreated', $true)
}