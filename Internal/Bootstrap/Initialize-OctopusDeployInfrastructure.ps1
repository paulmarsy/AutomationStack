function Initialize-OctopusDeployInfrastructure {
    Write-Host 'Deploying Octopus Deploy ARM Infrastructure...'
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusRg', 'OctopusStack#{UDP}')
    $octopusDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        infraResourceGroup = $CurrentContext.Get('InfraRg')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('Username')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
    }
    $CurrentContext.Set('OctopusHostName', (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName $CurrentContext.Get('OctopusRg')).DnsSettings.Fqdn)
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}:80/')

    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.enableencryption' -Mode Incremental -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $octopusDeploy.keyVaultSecretUrl.Value
    } | Out-Null
    Write-Host 'Creating Octopus Deploy SQL Database...'
    $dbName = 'OctopusDeploy'

    Remove-AzureRmSqlDatabase  -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -Force -ErrorAction Ignore  | Out-Null
    $octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
    Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=#{Username};Password=#{Password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
}
