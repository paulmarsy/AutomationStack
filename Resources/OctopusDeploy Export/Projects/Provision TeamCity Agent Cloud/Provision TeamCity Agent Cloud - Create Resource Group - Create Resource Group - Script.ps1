$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup) {
    Write-Output "Creating resource group '$ResourceGroupName' in location '$Location'"
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location | Out-Default
}
else {
    Write-Output "Using existing resource group '$ResourceGroupName'"
    $resourceGroup | Out-Default
}