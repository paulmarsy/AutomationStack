function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $Template,
        $TemplateParameters,
        [ValidateSet('Complete', 'Incremental')]$Mode
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment of '$Template' to $ResourceGroupName"

    Invoke-SharedScript Resources 'New-ResourceGroup' -ResourceGroupName $ResourceGroupName -Location ($CurrentContext.Get('AzureRegion'))

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

    Write-Host -NoNewLine "Testing ARM template $Template... "
    Test-AzureRmResourceGroupDeployment @args
    Write-Host 'valid' 

    try {
        Write-Host -NoNewLine "Starting ARM template deployment of $Template to $ResourceGroupName... "
        $deploymentName = '{0}-{1}' -f $Template, [datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19)
        $deployment = New-AzureRmResourceGroupDeployment -Name $deploymentName -Force @args
        Write-Host -ForegroundColor Green 'successfull!'
        Write-Host
        $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-String | % Trim | Out-Host
    }
    finally {
        Write-Host
        Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $deploymentName |
            % Properties |
            Sort-Object -Property timestamp |
            ? provisioningOperation -ne 'EvaluateDeploymentOutput' |        
            % {
                New-Object psobject -Property @{
                    Time = [System.Xml.XmlConvert]::ToDateTime($_.timestamp).ToString('T')
                    Operation = $_.provisioningOperation
                    Result = $_.statusCode
                    Message = $_.statusMessage
                    Duration = [Humanizer.TimeSpanHumanizeExtensions]::Humanize([System.Xml.XmlConvert]::ToTimeSpan($_.duration), 2, $null, [Humanizer.Localisation.TimeUnit]::Minute, [Humanizer.Localisation.TimeUnit]::Second)
                    Resource = ($_.targetResource.resourceType,$_.targetResource.resourceName -join '/')
                }
            } | Format-Table -AutoSize -Property @('Time','Duration','Operation','Result','Resource','Message') | Out-String | % Trim | Out-Host
    }
    Write-Host

    $deployment.Outputs
}   