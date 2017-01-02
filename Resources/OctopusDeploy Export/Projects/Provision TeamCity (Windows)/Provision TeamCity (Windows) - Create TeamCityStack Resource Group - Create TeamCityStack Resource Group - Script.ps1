$resourceGroup = Get-AzureRmResourceGroup -Name $TeamCityRg -ErrorAction SilentlyContinue
if(!$resourceGroup) {
    Write-Host "Creating resource group '$TeamCityRg' in location '$AzureRegion'"
    New-AzureRmResourceGroup -Name $TeamCityRg -Location $AzureRegion | Out-Null
}
else {
    Write-Host "Using existing resource group '$TeamCityRg'"
}