param($ResourceGroupName, $ServerName, $DatabaseName)

Remove-AzureRmSqlDatabase  -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Force -ErrorAction Ignore  | Out-Null

New-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic' | Out-Host

Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -State Enabled | Out-Host
