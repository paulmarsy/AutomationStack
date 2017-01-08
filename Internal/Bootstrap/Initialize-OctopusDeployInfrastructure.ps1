function Initialize-OctopusDeployInfrastructure {
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


    Write-Host 'Enabling KeyVault Disk Encryption for Octopus Deploy VM...'
    Start-ARMDeployment -ResourceGroupName $CurrentContext.Get('OctopusRg') -Template 'appserver.enableencryption' -Mode Incremental -TemplateParameters @{
        productName = 'Octopus'
        keyVaultResourceID = $CurrentContext.Get('KeyVaultResourceId')
        keyVaultSecretUrl = $octopusDeploy.keyVaultSecretUrl.Value
    } | Out-Null

    Write-Host 'Creating Octopus Deploy SQL Database...'
    $dbName = 'OctopusDeploy'
    Remove-AzureRmSqlDatabase  -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -Force -ErrorAction Ignore  | Out-Null
    $octopusDb = New-AzureRmSqlDatabase -ResourceGroupName $CurrentContext.Get('InfraRg') -ServerName $CurrentContext.Get('SqlServerName') -DatabaseName $dbName -CollationName 'SQL_Latin1_General_CP1_CI_AS' -Edition 'Basic'
    Set-AzureRmSqlDatabaseTransparentDataEncryption -ResourceGroupName $octopusDb.ResourceGroupName -ServerName $octopusDb.ServerName -DatabaseName $octopusDb.DatabaseName -State Enabled

    Write-Host "Waiting for DSC Node Compliance..."
    $currentPollWait = 10
    $previousPollWait = 0
    $continueToPoll = $true
    $maxWaitSeconds = 60
    while ($continueToPoll)
    {
        Start-Sleep -Seconds ([System.Math]::Min($currentPollWait, $maxWaitSeconds))
        $node = Get-AzureRmAutomationDscNode -ResourceGroupName $CurrentContext.Get('InfraRg') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') -Name $CurrentContext.Get('OctopusVMName')
        if ($node.Status -eq 'Compliant') {
                Write-Host "Node is compliant"
                $continueToPoll = $false
        }
        else {
                Write-Host "Node status is $($node.Status), waiting for compliance..."
        }
        if ($currentPollWait -lt $maxWaitSeconds){
                $temp = $previousPollWait
                $previousPollWait = $currentPollWait
                $currentPollWait = $temp + $currentPollWait
        }
    }
}
