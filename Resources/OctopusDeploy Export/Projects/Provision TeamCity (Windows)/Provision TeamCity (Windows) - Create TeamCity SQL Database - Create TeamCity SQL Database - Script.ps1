Remove-AzureRmSqlDatabase -ResourceGroupName $InfraRg -ServerName $SqlServerName -DatabaseName 'TeamCity' -Force -ErrorAction Ignore
$teamCityDb = New-AzureRmSqlDatabase -ResourceGroupName $InfraRg -ServerName $SqlServerName -DatabaseName 'TeamCity' -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
$teamCityDb
Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $teamCityDb.ResourceGroupName -ServerName $teamCityDb.ServerName -DatabaseName $teamCityDb.DatabaseName -State Enabled