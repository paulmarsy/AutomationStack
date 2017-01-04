function Resume-OctopusDeployConfiguration {
    Write-Host 'Applying Octopus Deploy DSC...'
    Register-AutomationDSCNode -AzureVMName $CurrentContext.Get('OctopusVMName') -AzureVMResourceGroup $CurrentContext.Get('OctopusRg') -Configuration 'OctopusDeploy' -Node 'Server'  -Parameters @{
        UDP = $CurrentContext.Get('UDP')
        OctopusAdminUsername = $CurrentContext.Get('Username')
        OctopusAdminPassword = $CurrentContext.Get('Password')
        ConnectionString = $CurrentContext.Get('OctopusConnectionString')
        HostHeader = $CurrentContext.Get('OctopusHostHeader')
    }
}