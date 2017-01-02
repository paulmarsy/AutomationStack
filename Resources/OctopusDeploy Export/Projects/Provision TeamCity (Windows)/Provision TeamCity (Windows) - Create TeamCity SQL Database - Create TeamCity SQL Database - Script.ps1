$teamCityDb = New-AzureRmSqlDatabase -ResourceGroupName $InfraRg -ServerName $SqlServerName -DatabaseName 'TeamCity' -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
$teamCityDb
Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $teamCityDb.ResourceGroupName -ServerName $teamCityDb.ServerName -DatabaseName $teamCityDb.DatabaseName -State Enabled

Set-OctopusVariable -Name TeamCityConnectionString -Value ('Server=tcp:{0}.database.windows.net,1433;Initial Catalog=TeamCity;Persist Security Info=False;User ID={1};Password={2};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;' -f $SqlServerName, $StackAdminUsername, $StackAdminPassword)