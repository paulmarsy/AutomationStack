function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $TemplateFile,
        $TemplateParameters
    )

    $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$resourceGroup) {
        $location = $CurrentContext.Get('AzureRegion')
        Write-Host "Creating resource group '$ResourceGroupName' in location '$location'"
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location | Out-Null
    }
    else {
        Write-Host "Using existing resource group '$ResourceGroupName'"
    }

    $TemplateFilePath = Join-Path -Resolve $ResourcesPath ('ARM Templates\{0}' -f $TemplateFile)

    Write-Host "Testing deployment..."
    Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath -TemplateParameterObject $TemplateParameters -Mode Complete

    Write-Host "Starting deployment..."
    New-AzureRmResourceGroupDeployment -Name ('AutomationStack-{0}-{1}' -f ([system.io.path]::GetFileNameWithoutExtension($TemplateFile)), $CurrentContext.Get('UDP')) -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath -TemplateParameterObject $TemplateParameters -Mode Complete -Force
}