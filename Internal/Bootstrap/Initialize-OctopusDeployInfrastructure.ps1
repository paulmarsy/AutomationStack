function Initialize-OctopusDeployInfrastructure {
    Write-Host 'Creating Octopus Deploy SQL Database...'
    $dbName = 'OctopusDeploy'
    Remove-AzureRmSqlDatabase  -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -Force -ErrorAction Ignore  | Out-Null
    $octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
    Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled

    Write-Host
    Write-Host 'Deploying Octopus Deploy ARM Infrastructure...'
    $CurrentContext.Set('OctopusVMName', 'OctopusVM')
    $CurrentContext.Set('OctopusRg', 'OctopusStack#{UDP}')
    $octopusDeploy = Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver' -Mode Complete -TemplateParameters @{
        udp = $CurrentContext.Get('UDP')
        infraResourceGroup = $CurrentContext.Get('InfraRg')
        productName = 'Octopus'
        vmAdminUsername = $CurrentContext.Get('Username')
        clientId = $CurrentContext.Get('ServicePrincipalClientId')
        registrationUrl = $CurrentContext.Get('AutomationRegistrationUrl')
        nodeConfigurationName = 'OctopusDeploy.Server'
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
    }

    Write-Host "Waiting for DSC Node Compliance..."
    $continueToPoll = $true
    while ($continueToPoll)
    {
        Start-Sleep -Seconds 30
        $node = Get-AzureRmAutomationDscNode -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Name $CurrentContext.Get('OctopusVMName')
        if ($node.Status -eq 'Compliant') {
                Write-Host "Node is compliant"
                $continueToPoll = $false
        }
        else {
                Write-Host "Node status is $($node.Status), waiting for compliance..."
        }
    }

    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.enableencryption' -Mode Incremental -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $octopusDeploy.keyVaultSecretUrl.Value
    } | Out-Null
}
