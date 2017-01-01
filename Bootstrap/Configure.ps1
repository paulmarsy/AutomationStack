param(
    $AzureRegion = 'North Europe'
)

$currentStack = & (Join-Path $PSScriptRoot 'CurrentStack.ps1') -Guid ([guid]::NewGuid().guid)

Write-Host 'Creating Octostache Config Store...'
. (Join-Path $PSScriptRoot '..\Utils\Octosprache.ps1')
$context = [octosprache]::new($currentStack.UDP)
$context.Set('UDP', $currentStack.UDP)
$context.Set('Username', $currentStack.Username)
$context.Set('Password', $currentStack.Password)
$context.Set('Name', 'AutomationStack#{UDP}')

$azureRmContext = Get-AzureRmContext
$context.Set('AzureTenantId', $azureRmContext.Tenant.TenantId)
$context.Set('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)
$context.Set('AzureRegion', $AzureRegion)

Write-Host 'Deploying core infrastructure...'
$context.Set('InfraRg', 'AutomationStack#{UDP}')
$context.Set('SqlServerName', 'sqlserver#{UDP}')
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName $context.Get('InfraRg') -Location $context.Get('AzureRegion') -TemplateFile 'infrastructure.json' -TemplateParameters @{
    udp = $context.Get('UDP')
    sqlAdminUsername = $context.Get('Username')
    sqlAdminPassword = $context.Get('Password')
}

Write-Host 'Creating Azure Service Principal...'
$app = New-AzureRmADApplication -DisplayName $context.Get('Name') -IdentifierUris "http://$($context.Get('Name')).local" -Password $context.Get('Password')
$context.Set('ServicePrincipalClientId', $app.ApplicationId)
$servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
Start-Sleep -Seconds 20
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName  $app.ApplicationId

Write-Host 'Configuring Resources Storage Account...'
& (Join-Path $PSScriptRoot 'DeployResources.ps1') -Context $context

Write-Host 'Deploying Octopus Deploy...'
& (Join-Path $PSScriptRoot 'OctopusDeploy.ps1') -Context $context

Write-Host -ForegroundColor Green 'Octopus Deploy Running at: ' $context.Get('OctopusHostHeader')
