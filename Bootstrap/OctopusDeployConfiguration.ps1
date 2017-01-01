param($Context)

Write-Host 'Applying Octopus Deploy DSC...'
& (Join-Path $PSScriptRoot 'DeployDSC.ps1') -UDP $Context.Get('UDP') -AzureVMName $Context.Get('OctopusVMName') -AzureVMResourceGroup $Context.Get('OctopusRg') -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters @{
    UDP = $Context.Get('UDP')
    OctopusAdminUsername = $Context.Get('Username')
    OctopusAdminPassword = $Context.Get('Password')
    ConnectionString = $Context.Get('OctopusConnectionString')
    HostHeader = $Context.Get('OctopusHostHeader')
}

Write-Host 'Importing Automation Stack functionality into Octopus Deploy...'
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $Context.Get('OctopusRg') -Location $Context.Get('AzureRegion') -VMName $Context.Get('OctopusVMName') -Name "OctopusImport" -StorageAccountName $Context.Get('StackResourcesName') -StorageAccountKey $Context.Get('StackResourcesKey')  -FileName "OctopusImport.ps1" -ContainerName "scripts"
Get-AzureRmVMExtension -ResourceGroupName $Context.Get('OctopusRg') -VMName $Context.Get('OctopusVMName') -Name "OctopusImport"  -Status | % SubStatuses | % Message | % Replace '\n' "`n"