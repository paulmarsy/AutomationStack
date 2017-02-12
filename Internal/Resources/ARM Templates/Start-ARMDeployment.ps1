function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        [ValidateSet('File','Uri')]$Mode,
        $Template,
        $TemplateParameters
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment of '$Template' to $ResourceGroupName"

    $global:templateDeployArgs = $TemplateParameters
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

    try {
        Write-Host -NoNewLine "Starting ARM template deployment of $Template to $ResourceGroupName... "
        $deployment = New-AzureRmResourceGroupDeployment -Force @templateDeployArgs -DeploymentDebugLogLevel All -WarningAction Ignore
        Write-Host -ForegroundColor Green 'successfull'
        Write-Host
        $deployment | Format-List -Property @('DeploymentName','ResourceGroupName','Mode','ProvisioningState','Timestamp','ParametersString', 'OutputsString') | Out-String | % Trim | Out-Host
    }
    finally {
        Write-Host
        Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $Template -ErrorAction Ignore |
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