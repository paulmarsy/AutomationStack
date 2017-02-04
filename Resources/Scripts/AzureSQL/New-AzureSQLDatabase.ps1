param($ResourceGroupName, $ServerName, $DatabaseName, [switch]$Force)

if (Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -ErrorAction Ignore) {
    Write-Warning "Database $DatabaseName already exists"
    if ($Force) {
        Write-Warning 'Removing existing database...'
        Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Force | Out-Null
    } else {
        Write-Warning 'Skipping database creation...'
        return
    }
}
New-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Edition Basic -Tag @{ application = 'AutomationStack'; udp = (Get-AzureRmResourceGroup -Name $ResourceGroupName).Tags.udp } | Out-Host

Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -State Enabled | Out-Host
