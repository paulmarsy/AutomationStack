function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $Template,
        $TemplateParameters,
        [ValidateSet('Complete', 'Incremental')]$Mode
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting $ResourceGroupName Resource Group Deployment"

    Invoke-SharedScript Resources 'New-ResourceGroup' -ResourceGroupName $ResourceGroupName -Location ($CurrentContext.Get('AzureRegion'))

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

    Write-Host -NoNewLine "Testing ARM deployment of '$Template'... "
    Test-AzureRmResourceGroupDeployment @args
    Write-Host 'valid' 

    Write-Host -NoNewLine "Starting ARM deployment of '$Template' to $ResourceGroupName... "
    $deployment = New-AzureRmResourceGroupDeployment -Name ('{0}-{1}' -f $Template, [datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19)) -Force @args
    Write-Host -ForegroundColor Green 'successfull!'
    Write-Host
    $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-String | % Trim | Out-Host
    Write-Host

    Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $deployment.DeploymentName | % Properties | % {
        New-Object psobject -Property @{
            Time = [System.Xml.XmlConvert]::ToDateTime($_.timestamp).ToString('T')
            Operation = $_.provisioningOperation
            Result = $_.statusCode
            Message = $_.statusMessage
            Duration = [Humanizer.TimeSpanHumanizeExtensions]::Humanize([System.Xml.XmlConvert]::ToTimeSpan($_.duration), 2)
            ResourceName = $_.targetResource.resourceName
        }
    } | Sort-Object -Property Time | Format-Table -AutoSize -Property @('Time','Duration','Operation','Result','ResourceName','Message') | Out-Host
    Write-Host

    $deployment.Outputs
}   