function Remove-AutomationStack {
    param(
        $UDP,
        [switch]$PassThru
    )

    if (!$UDP) {
        $UDP = $CurrentContext.Get('UDP')
    }

    Write-Host 'Removing Service Principal...'
    Get-AzureRmADApplication -DisplayNameStartWith ('AutomationStack{0}' -f $UDP) | Remove-AzureRmADApplication -Force

    $jobs = @(
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('TeamCityStack{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('TeamCityAgents{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('OctopusStack{0}' -f $UDP) -PassThru $true)
        (Invoke-SharedScript Resources 'Remove-ResourceGroup' -ResourceGroupName ('AutomationStack{0}' -f $UDP) -PassThru $true)
    )

    $configFile = Join-Path $script:DeploymentsPath ('{0}.json' -f $UDP)
    if (Test-Path $configFile) {
        Write-Host 'Removing deployment config file...'
        Remove-Item -Path $configFile -Force
    }

    if ($PassThru) { return $jobs }
    else { $jobs | Receive-Job -AutoRemoveJob -Wait }
}