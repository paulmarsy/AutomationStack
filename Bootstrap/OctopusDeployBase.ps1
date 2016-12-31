param($Context)

$Context.Set('OctopusVMName', 'OctopusVM')
$Context.Set('OctopusRg', 'OctopusStack#{UDP}')

Write-Host 'Creating Octopus Deploy ARM Infrastructure...'
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName $Context.Get('OctopusRg') -Location $Context.Get('AzureRegion') -TemplateFile 'appserver.json' -TemplateParameters @{
    udp = $Context.Get('UDP')
    infraResourceGroup = $Context.Get('InfraRg')
    productName = 'Octopus'
    vmAdminUsername = $Context.Get('Username')
    vmAdminPassword = $Context.Get('Password')
}

Write-Host 'Creating Octopus Deploy SQL Database...'
$octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $Context.Get('InfraRg') -ServerName $Context.Get('SqlServerName') -DatabaseName 'OctopusDeploy' -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled

Write-Host 'Applying Octopus Deploy DSC...'
$Context.Set('OctopusHostName', (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName $Context.Get('OctopusRg')).DnsSettings.Fqdn)
$Context.Set('OctopusHostHeader', 'http://#{OctopusHostName}:80/')
$Context.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=#{Username};Password=#{Password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
& (Join-Path $PSScriptRoot 'DeployDSC.ps1') -UDP $Context.Get('UDP') -AzureVMName $Context.Get('OctopusVMName') -AzureVMResourceGroup $Context.Get('OctopusRg') -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters @{
    UDP = $Context.Get('UDP')
    OctopusAdminUsername = $Context.Get('Username')
    OctopusAdminPassword = $Context.Get('Password')
    ConnectionString = $Context.Get('OctopusConnectionString')
    HostHeader = $Context.Get('OctopusHostHeader')
}