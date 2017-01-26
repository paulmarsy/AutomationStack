function Remove-AutomationStack {
    param(
        $UDP
    )

    if (!$UDP) {
        $UDP = $CurrentContext.Get('UDP')
    }

    Write-Host 'Removing Service Principal...'
    Get-AzureRmADApplication -DisplayNameStartWith ('AutomationStack{0}' -f $UDP) | Remove-AzureRmADApplication -Force

    @(
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('TeamCityStack{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('TeamCityAgents{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('OctopusStack{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('AutomationStack{0}' -f $UDP) -PassThru $true)
    ) | Receive-Job -AutoRemoveJob -Wait

    $configFile = Join-Path $script:DeploymentsPath ('{0}.config.json' -f $UDP)
    if (Test-Path $configFile) {
        Write-Host 'Removing deployment config file...'
        Remove-Item -Path $configFile -Force
    }
    $metricsFile = Join-Path $script:DeploymentsPath ('{0}.metrics.json' -f $UDP)
    if (Test-Path $metricsFile) {
        Write-Host 'Removing deployment metrics file...'
        Remove-Item -Path $metricsFile -Force
    }

    $script:CurrentContext = $null

    Write-Host -ForegroundColor Green "Removed deployment $UDP successfully"
}