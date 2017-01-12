param($ResourceGroupName, $Location)

$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'"
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
}
else {
    Write-Host "Using existing resource group '$ResourceGroupName'"
}