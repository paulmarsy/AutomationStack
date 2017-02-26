function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        $Template,
        $TemplateParameters
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment of '$Template' to $ResourceGroupName"

    $templateDeployArgs = $TemplateParameters.Clone()
    $templateDeployArgs.Add('ResourceGroupName', $ResourceGroupName)
    $templateDeployArgs.Add('Mode', 'Incremental')
    $templateDeployArgs.Add('TemplateFile', (Join-Path -Resolve $ResourcesPath ('ARM Templates\{0}.json' -f $Template))) 
     
    $startTime = Get-Date
    try {
        Write-Host -NoNewLine "Starting ARM template deployment of $Template to $ResourceGroupName... "
        $deployment = New-AzureRmResourceGroupDeployment -Force @templateDeployArgs
        Write-Host -ForegroundColor Green 'successfull'
        Show-ARMDeployment -ResourceGroupName $ResourceGroupName -DeploymentName $Template -StartTime $startTime
        Write-Host
        $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-String | % Trim | Out-Host
    }
    catch {
        Show-ARMDeployment -ResourceGroupName $ResourceGroupName -DeploymentName $Template -StartTime $startTime -HasError
        throw
    }
    Write-Host

    $deployment.Outputs
}   