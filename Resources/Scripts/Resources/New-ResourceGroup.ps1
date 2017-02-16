param($UDP, $ResourceGroupName, $Location)

$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Ignore
if(!$resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'"
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{ application = 'AutomationStack'; udp = $UDP } | Out-Null
}
else {
    Write-Host "Using existing resource group '$ResourceGroupName'"
}