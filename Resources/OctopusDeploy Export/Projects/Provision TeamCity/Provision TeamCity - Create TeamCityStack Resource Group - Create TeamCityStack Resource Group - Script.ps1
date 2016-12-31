$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$AzureRegion'"
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion | Out-Null
}
else {
    Write-Host "Using existing resource group '$ResourceGroupName'"
}
