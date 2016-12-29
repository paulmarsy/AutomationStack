param(
     $ResourceGroupName,
     $Location,
     $TemplateFile,
     $TemplateParameters
)

$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup) {
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'"
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
}
else {
    Write-Host "Using existing resource group '$ResourceGroupName'"
}

$TemplateFilePath = Join-Path -Resolve $PSScriptRoot ('..\Resources\ARM Templates\{0}' -f $TemplateFile)

Write-Host "Testing deployment..."
Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath -TemplateParameterObject $TemplateParameters

Write-Host "Starting deployment..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath -DeploymentDebugLogLevel All -TemplateParameterObject $TemplateParameters
