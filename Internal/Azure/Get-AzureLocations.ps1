function Get-AzureLocations {
    <#
        Get-AzureRmLocations requires you to be authenticated, but need the location passed into the cmdlet before auth
        To generate:
            Get-AzureRmLocation | % { "@{ Name = '$($_.DisplayName)'; Value = '$($_.Location)' }" } | Set-Clipboard
    #>
    @(
        @{ Name = 'East Asia'; Value = 'eastasia' }
        @{ Name = 'Southeast Asia'; Value = 'southeastasia' }
        @{ Name = 'Central US'; Value = 'centralus' }
        @{ Name = 'East US'; Value = 'eastus' }
        @{ Name = 'East US 2'; Value = 'eastus2' }
        @{ Name = 'West US'; Value = 'westus' }
        @{ Name = 'North Central US'; Value = 'northcentralus' }
        @{ Name = 'South Central US'; Value = 'southcentralus' }
        @{ Name = 'North Europe'; Value = 'northeurope' }
        @{ Name = 'West Europe'; Value = 'westeurope' }
        @{ Name = 'Japan West'; Value = 'japanwest' }
        @{ Name = 'Japan East'; Value = 'japaneast' }
        @{ Name = 'Brazil South'; Value = 'brazilsouth' }
        @{ Name = 'Australia East'; Value = 'australiaeast' }
        @{ Name = 'Australia Southeast'; Value = 'australiasoutheast' }
        @{ Name = 'Canada Central'; Value = 'canadacentral' }
        @{ Name = 'Canada East'; Value = 'canadaeast' }
        @{ Name = 'UK South'; Value = 'uksouth' }
        @{ Name = 'UK West'; Value = 'ukwest' }
        @{ Name = 'West Central US'; Value = 'westcentralus' }
        @{ Name = 'West US 2'; Value = 'westus2' }
    )
}