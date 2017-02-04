param($ResourceGroupName, $ServerName, $DatabaseName)

Remove-AzureRmSqlDatabase  -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Force -ErrorAction Ignore  | Out-Null

New-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Edition Basic -Tag @{ application = 'AutomationStack'; udp = (Get-AzureRmResourceGroup -Name $ResourceGroupName).Tags.udp } | Out-Host

Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -State Enabled | Out-Host
