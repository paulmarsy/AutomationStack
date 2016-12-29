param(
    $AzureRegion = 'North Europe',
    $UDP,
    $Username,
    $Password
)

Write-Host 'Octopus Deploy ARM Infrastructure...'
$octoArmParams = @{
    udp = $UDP
    infraResourceGroup = ('AutomationStack{0}' -f $UDP)
    productName = 'Octopus'
    vmAdminUsername = $Username
    vmAdminPassword = $Password
}
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName ('OctopusStack{0}' -f $UDP) -Location $AzureRegion -TemplateFile 'appserver.json' -TemplateParameters $octoArmParams

$sqlServerName = 'sqlserver{0}' -f $UDP
Write-Host 'Octopus Deploy SQL Database...'
$octopusDb = New-AzureRmSqlDatabase -ResourceGroupName ('AutomationStack{0}' -f $UDP) -ServerName $sqlServerName -DatabaseName 'OctopusDeploy' -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled

Write-Host 'Octopus Deploy DSC Configuration...'
$fqdn = (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName ('OctopusStack{0}' -f $UDP)).DnsSettings.Fqdn
$hostHeader = 'http://{0}:80/' -f $fqdn
$octoDscParams = @{
    UDP = $UDP
    OctopusAdminUsername = $Username
    OctopusAdminPassword = $Password
    ConnectionString = ('Server=tcp:{0}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID={1};Password={2};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;' -f $sqlServerName, $Username, $Password)
    HostHeader = $hostHeader
}
& (Join-Path $PSScriptRoot 'DeployDSC.ps1') -UDP $UDP -AzureVMName 'OctopusVM' -AzureVMResourceGroup ('OctopusStack{0}' -f $UDP) -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters $octoDscParams

Write-Host -ForegroundColor Green "Octopus Deploy Running at: $hostHeader"

Write-Host 'Generating Octopus API Key...'
Invoke-WebRequest -UseBasicParsing -Uri ('{0}/api/users/authenticate/usernamepassword' -f $hostHeader) -Method Post -Body (@{Username = $Username; Password = $Password; RememberMe = $false }| ConvertTo-Json) -SessionVariable octopusSession | Out-Null

$myOctopusUserId = Invoke-WebRequest -UseBasicParsing -Uri 'http://octopus-stack3bdc.westeurope.cloudapp.azure.com/api/users/me' -WebSession $octopusSession | % Content | ConvertFrom-Json | % Id
Write-Host "User '$Username' id: $myOctopusUserId"
$apiKey = Invoke-WebRequest -UseBasicParsing -Uri ('{0}/api/users/{1}/apikeys' -f $hostHeader, $myOctopusUserId) -WebSession $octopusSession -Method Post -Body (@{Purpose='AutomationStack'} | ConvertTo-Json) | % Content | ConvertFrom-Json | % ApiKey
Write-Host "Octopus API Key: $apiKey"