function Remove-AutomationStack {
    param(
        $UDP
    )

    if (!$UDP) {
        $UDP = $CurrentContext.Get('UDP')
    }
    $UDP = $UDP.ToUpperInvariant()

    Write-Host 'Removing Service Principal...'
    Get-AzureRmADApplication -DisplayNameStartWith ('AutomationStack{0}' -f $UDP) | Remove-AzureRmADApplication -Force

    Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('TCAgentStack{0}' -f $UDP)

    Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('AutomationStack{0}' -f $UDP)

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