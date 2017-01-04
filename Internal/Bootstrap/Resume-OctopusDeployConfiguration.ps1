function Resume-OctopusDeployConfiguration {
    Write-Host 'Applying Octopus Deploy DSC...'
    Register-AutomationDSCNode -AzureVMName $CurrentContext.Get('OctopusVMName') -AzureVMResourceGroup $CurrentContext.Get('OctopusRg') -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters @{
        UDP = $CurrentContext.Get('UDP')
        OctopusAdminUsername = $CurrentContext.Get('Username')
        OctopusAdminPassword = $CurrentContext.Get('Password')
        ConnectionString = $CurrentContext.Get('OctopusConnectionString')
        HostHeader = $CurrentContext.Get('OctopusHostHeader')
    }

    Write-Host 'Importing Automation Stack functionality into Octopus Deploy...'
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $CurrentContext.Get('OctopusRg') -Location $CurrentContext.Get('AzureRegion') -VMName $CurrentContext.Get('OctopusVMName') -Name "OctopusImport" -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')  -FileName "OctopusImport.ps1" -ContainerName "scripts"
    Get-AzureRmVMExtension -ResourceGroupName $ContCurrentContextext.Get('OctopusRg') -VMName $CurrentContext.Get('OctopusVMName') -Name "OctopusImport"  -Status | % SubStatuses | % Message | % Replace '\n' "`n"
}