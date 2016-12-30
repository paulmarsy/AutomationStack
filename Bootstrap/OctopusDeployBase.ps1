param($Context)

$vmName = 'OctopusVM'
$rg = 'OctopusStack{0}' -f $Context.UDP

Write-Host 'Creating Octopus Deploy ARM Infrastructure...'
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName $rg -Location $Context.Region -TemplateFile 'appserver.json' -TemplateParameters @{
    udp = $Context.UDP
    infraResourceGroup = $Context.InfraRg
    productName = 'Octopus'
    vmAdminUsername = $Context.Username
    vmAdminPassword = $Context.Password
}

Write-Host 'Creating Octopus Deploy SQL Database...'
$sqlServerName = 'sqlserver{0}' -f $Context.UDP
$octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $Context.InfraRg -ServerName $sqlServerName -DatabaseName 'OctopusDeploy' -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled

Write-Host 'Applying Octopus Deploy DSC...'
$fqdn = (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName $rg).DnsSettings.Fqdn
$hostHeader = 'http://{0}:80/' -f $fqdn
& (Join-Path $PSScriptRoot 'DeployDSC.ps1') -UDP $Context.UDP -AzureVMName $vmName -AzureVMResourceGroup $rg -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters @{
    UDP = $Context.UDP
    OctopusAdminUsername = $Context.Username
    OctopusAdminPassword = $Context.Password
    ConnectionString = ('Server=tcp:{0}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID={1};Password={2};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;' -f $sqlServerName, $Context.Username, $Context.Password)
    HostHeader = $hostHeader
}

@{
    HostHeader = $hostHeader
    VMName = $vmName
    VMResourceGroup = $rg
}