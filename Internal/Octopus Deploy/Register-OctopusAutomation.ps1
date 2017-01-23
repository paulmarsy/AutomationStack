function Register-OctopusAutomation {
    Write-Host "Creating Octopus Deploy Service Credentials..."

    Remove-AzureRmAutomationCredential -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Name OctopusDeployServiceAccount -ErrorAction Ignore
    $octopusDeployServiceAccount = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CurrentContext.Get('OctopusAutomationCredentialUsername'), (ConvertTo-SecureString $CurrentContext.Get('OctopusAutomationCredentialPassword') -AsPlainText -Force)
    New-AzureRmAutomationCredential -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Name OctopusDeployServiceAccount -Value $octopusDeployServiceAccount | Out-Host
    
    Write-Host "Importing Octopus Deploy DSC Configuration..."

    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusConnectionString', 'Server=tcp:#{SqlServerName}.database.windows.net,1433;Initial Catalog=OctopusDeploy;Persist Security Info=False;User ID=#{StackAdminUsername};Password=#{SqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;')
    $CurrentContext.Set('OctopusHostName', 'octopusstack-#{UDP}.#{AzureRegionValue}.cloudapp.azure.com')
    $CurrentContext.Set('OctopusHostHeader', 'http://#{OctopusHostName}/')

    Invoke-SharedScript Automation 'Import-OctopusConfig' -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1') -InfraRg  $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') `
        -VMName $CurrentContext.Get('OctopusVMName') `
        -ConnectionString $CurrentContext.Get('OctopusConnectionString') `
        -OctopusHostName $CurrentContext.Get('OctopusHostName') `
        -OctopusVersionToInstall 'latest' | Out-Host
}