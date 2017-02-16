function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        [ValidateSet('File','Uri')]$Mode,
        $Template,
        $TemplateParameters
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment of '$Template' to $ResourceGroupName"

    $templateDeployArgs = $TemplateParameters.Clone()
    $templateDeployArgs.Add('ResourceGroupName', $ResourceGroupName)
    $templateDeployArgs.Add('Mode', 'Incremental')

    switch ($Mode) {
        'File' { $templateDeployArgs.Add('TemplateFile', (Join-Path -Resolve $ResourcesPath ('ARM Templates\{0}.json' -f $Template))) }
        'Uri' {
            $context = Get-StackResourcesContext
            $templateDeployArgs.Add('TemplateUri', (New-AzureStorageBlobSASToken -Container arm -Blob "${Template}.json" -Permission r -ExpiryTime (Get-Date).AddHours(1) -FullUri -Protocol HttpsOnly -Context $context))
            $templateDeployArgs.Add('templateSasToken', (ConvertTo-SecureString -String (New-AzureStorageContainerSASToken -Name arm -Permission r -ExpiryTime (Get-Date).AddHours(1) -Protocol HttpsOnly -Context $context) -AsPlainText -Force))
        }
    }

    Write-Host -NoNewLine "Testing ARM template $Template... "
    Test-AzureRmResourceGroupDeployment @templateDeployArgs
    Write-Host 'valid'
     
    $startTime = Get-Date
    try {
        Write-Host -NoNewLine "Starting ARM template deployment of $Template to $ResourceGroupName... "
        $deployment = New-AzureRmResourceGroupDeployment -Force @templateDeployArgs -DeploymentDebugLogLevel All -WarningAction Ignore
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