param(
    $AzureRegion = 'North Europe'
)

Write-Host ('*'*40)
Write-Host "AutomationStack Deployment Details" 
$deploymentGuid = [guid]::NewGuid().guid
$UDP = $deploymentGuid.Substring(9,4)
Write-Host "Unique Deployment Prefix: $UDP" 
$Username = 'Stack'
Write-Host "Admin Username: $Username"  
$Password = $deploymentGuid.Substring(0,8) + (($deploymentGuid.Substring(24,10).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join '')
Write-Host "Admin Password: $Password"  
Write-Host ('*'*40)

Write-Host 'Deploying core infrastructure...'
$infraParams = @{
    udp = $UDP
    sqlAdminUsername = $Username
    sqlAdminPassword = $Password 
}
& (Join-Path $PSScriptRoot 'DeployARM.ps1') -ResourceGroupName ('AutomationStack{0}' -f $UDP) -Location $AzureRegion -TemplateFile 'infrastructure.json' -TemplateParameters $infraParams

& (Join-Path $PSScriptRoot 'OctopusDeploy.ps1') -AzureRegion $AzureRegion -UDP $UDP -Username $Username -Password $Password