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
        (Remove-AzureResourceGroupAsync 'TeamCity' ('TeamCityStack{0}' -f $UDP))
        (Remove-AzureResourceGroupAsync 'Octopus Deploy' ('OctopusStack{0}' -f $UDP))
        (Remove-AzureResourceGroupAsync 'Infrastructure' ('AutomationStack{0}' -f $UDP))
    )

    $configFile = Join-Path $script:DeploymentsPath ('{0}.json' -f $UDP)
    if (Test-Path $configFile) {
        Write-Host 'Removing deployment config file...'
        Remove-Item -Path $configFile -Force
    }

    if ($PassThru) { return $jobs }
    else { $jobs | Wait-Job | Receive-Job -AutoRemoveJob }
}