function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $Template,
        $TemplateParameters,
        [ValidateSet('Complete', 'Incremental')]$Mode
    )

    Write-Host
    $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$resourceGroup) {
        $location = $CurrentContext.Get('AzureRegion')
        Write-Host "Creating resource group '$ResourceGroupName' in location '$location'"
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location | Out-Null
    }
    else {
        Write-Host "Using existing resource group '$ResourceGroupName'"
    }
    Write-Host
    $args = @{
        ResourceGroupName = $ResourceGroupName
        TemplateFile = (Join-Path -Resolve $ResourcesPath ('ARM Templates\{0}.json' -f $Template))
        Mode = $Mode
    }

    $TemplateParametersFilePath = Join-Path $ResourcesPath ('ARM Templates\{0}.parameters.json' -f $Template)
    if (Test-Path $TemplateParametersFilePath) {
        $tokenisedTemplateParameterFile = Join-Path $TempPath ('{0}.parameters.json' -f $Template)
        $CurrentContext.ParseFile($TemplateParametersFilePath, $tokenisedTemplateParameterFile)
        $args += @{ TemplateParameterFile = $tokenisedTemplateParameterFile }
        $args += $TemplateParameters
    } else {
        $args += @{ TemplateParameterObject = $TemplateParameters }
    }

    Write-Host "Testing deployment..."
    Test-AzureRmResourceGroupDeployment @args

    Write-Host "Starting deployment..."
    $deployment = New-AzureRmResourceGroupDeployment -Name ('{0}-{1}' -f $Template, [datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19)) -Force @args

    $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-Host
    $deployment.Outputs
} 