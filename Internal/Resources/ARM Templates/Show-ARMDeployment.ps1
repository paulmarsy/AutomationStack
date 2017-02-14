function Show-ARMDeployment {
    param($ResourceGroupName, $DeploymentName, $StartTime, [switch]$HasError)
    try {
        if ($HasError) {
            Get-AzureRmLog -ResourceGroup $ResourceGroupName -StartTime $StartTime -DetailedOutput | Sort-Object -Property EventTimestamp | Format-Table -Property EventName,Status,OperationName,Properties -Expand Both | Out-Host
        }
        Write-Host
        Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName |
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
    catch {}
}