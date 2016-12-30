param(
    $AzureRegion = 'North Europe'
)

Write-Host 'Creating Octostache tokeniser...'
. (Join-Path $PSScriptRoot '..\Utils\Get-OctopusEncryptedValue.ps1')
. (Join-Path $PSScriptRoot '..\Utils\Octosprache.ps1')
$octosprache = [octosprache]::new()
$azureRmContext = Get-AzureRmContext
$octosprache.Add('AzureTenantId', $azureRmContext.Tenant.TenantId)
$octosprache.Add('AzureSubscriptionId', $azureRmContext.Subscription.SubscriptionId)

$Context = & (Join-Path $PSScriptRoot 'currentStack.ps1') -Guid ([guid]::NewGuid().guid) -AzureRegion $AzureRegion
$octosprache.Add('UDP', $Context.UDP)
$octosprache.Add('AzureRegion', $AzureRegion)
$octosprache.Add('Username', $Context.Username)
$octosprache.Add('Password', $Context.Password)


Write-Host 'Deploying core infrastructure...'
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName $Context.InfraRg -Location $Context.Region -TemplateFile 'infrastructure.json' -TemplateParameters @{
    udp = $Context.UDP
    sqlAdminUsername = $Context.Username
    sqlAdminPassword = $Context.Password 
}

Write-Host 'Creating Azure Service Principal...'
$app = New-AzureRmADApplication -DisplayName $Context.Name -IdentifierUris "http://$($Context.Name).local" -Password $Context.Password
$octosprache.Add('ServicePrincipalClientId', $app.ApplicationId)
$octosprache.Add('ServicePrincipalEncryptedPassword', (Get-OctopusEncryptedValue -Password $Context.Password -Value $Context.Password))
$servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
Start-Sleep -Seconds 20
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName  $app.ApplicationId

Write-Host 'Deploying Octopus Deploy...'
$octopusStack = & (Join-Path $PSScriptRoot 'OctopusDeployBase.ps1') -Context $Context

Write-Host 'Uploading Octopus Deploy Configuration...'
& (Join-Path $PSScriptRoot 'OctopusDeployUpload.ps1') -Context $Context -octosprache $octosprache

Write-Host 'Importing Automation Stack functionality into Octopus Deploy...'
& (Join-Path $PSScriptRoot 'OctopusDeployImport.ps1') -OctopusStack  $octopusStack -Context $Context

Write-Host -ForegroundColor Green "Octopus Deploy Running at: $($octopusStack.HostHeader)"
