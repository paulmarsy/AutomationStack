function Start-ARMDeployment {
    param(
        $ResourceGroupName,
        [ValidateSet('File','Uri')]$Mode,
        $Template,
        $TemplateParameters
    )

    Write-Host 
    Write-Host -ForegroundColor Cyan "`tStarting Resource Group Deployment of '$Template' to $ResourceGroupName"

    $args = @{
        ResourceGroupName = $ResourceGroupName
        TemplateParameterObject = $TemplateParameters
        Mode = 'Incremental'
    }
    $args += switch ($Mode) {
        'File' { @{ TemplateFile = (Join-Path -Resolve $ResourcesPath ('ARM Templates\{0}.json' -f $Template)) } }
        'Uri' {
            @{
                TemplateUri = (New-AzureStorageBlobSASToken -Container arm -Blob $Template -Policy 'TemplateDeployment' -FullUri -Protocol HttpsOnly)
                templateSasToken = (New-AzureStorageContainerSASToken -Name arm -Policy 'TemplateDeployment' -Protocol HttpsOnly)
            }
        }
    }

    Write-Host -NoNewLine "Testing ARM template $Template... "
    Test-AzureRmResourceGroupDeployment @args
    Write-Host 'valid' 

    try {
        Write-Host -NoNewLine "Starting ARM template deployment of $Template to $ResourceGroupName... "
        $deployment = New-AzureRmResourceGroupDeployment -Force @args 
        Write-Host -ForegroundColor Green 'successfull'
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