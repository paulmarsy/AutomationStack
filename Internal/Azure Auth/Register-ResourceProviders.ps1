function Register-ResourceProviders {
    Write-Host
    Write-Host "Registering Azure Resource Providers:"
       @(
           'Microsoft.Automation'
           'Microsoft.KeyVault'
           'Microsoft.Network'
           'Microsoft.Sql'
           'Microsoft.Storage'
           'Microsoft.Insights' # Enables the basic monitoring functionality in Azure Portal blades
           'Microsoft.Compute'
       ) | % {
            Write-Host "`t$_"
            Register-AzureRmResourceProvider -ProviderNamespace $_
       }
       Write-Host
}