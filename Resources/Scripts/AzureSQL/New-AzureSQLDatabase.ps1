    $dbName = 'OctopusDeploy'
    Remove-AzureRmSqlDatabase  -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -Force -ErrorAction Ignore  | Out-Null
    $octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
    Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled
