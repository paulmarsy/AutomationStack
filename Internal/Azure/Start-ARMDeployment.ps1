function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $Template,
        $TemplateParameters,
        [ValidateSet('Complete', 'Incremental')]$Mode
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment"

    Invoke-SharedScript Resources 'New-ResourceGroup' -ResourceGroupName $ResourceGroupName -Location $CurrentContext.Get('AzureRegion')

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

    Write-Host

    Write-Host "Testing ARM deployment..."
    Test-AzureRmResourceGroupDeployment @args

    Write-Host "Starting ARM deployment..."
    $deployment = New-AzureRmResourceGroupDeployment -Name ('{0}-{1}' -f $Template, [datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19)) -Force @args

    $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-Host
    Write-Host
    $deployment.Outputs
} 