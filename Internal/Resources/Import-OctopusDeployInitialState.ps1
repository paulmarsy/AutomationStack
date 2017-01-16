function Import-OctopusDeployInitialState {
    Write-Host 'Initialising Azure VM Custom Script Extension...'

    try {
        & net use O: \\$CurrentContext.Get('StackResourcesName').file.core.windows.net\octopusdeploy /persistent:no /u:$CurrentContext.Get('StackResourcesName') $CurrentContext.Get('StackResourcesKey')
        $logFile = 'O:\CustomScript.log'        
        $logPosition = 0
        New-Item -Path $logFile -ItemType File | Out-Null

        $azureprofile = [System.IO.Path]::GetTempFileName()
        Save-AzureRmProfile -Path $azureprofile -Force

        $job = Start-Job -ScriptBlock {
            param($SubscriptionId, $AzureProfile, $ResourceGroupName, $Location, $VMName, $Name, $StorageAccountName, $StorageAccountKey, $FileName, $ContainerName, $Run)
            Select-AzureRmProfile -Profile $AzureProfile
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId

            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -Name $Name -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -FileName $FileName -ContainerName $ContainerName -Run $Run
            Remove-Item -Path $AzureProfile -Force | Out-Null
        } -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureprofile, $CurrentContext.Get('OctopusRg'), $CurrentContext.Get('AzureRegion'), $CurrentContext.Get('OctopusVMName'), "OctopusImport", $CurrentContext.Get('StackResourcesName'), $CurrentContext.Get('StackResourcesKey'), "OctopusImport.ps1", "scripts", 'OctopusImport.ps1')

        while ($job.State -eq 'Running') {
            Start-Sleep 5
            Get-Content -Path $logFile | Select-Object -Skip $logPosition | % { $logPosition++; $_ | Out-Host }
        }
        Write-Host
        Write-Host ('Custom Script Extension finished with state: {0} after {1}' -f $job.State, ([Humanizer.TimeSpanHumanizeExtensions]::Humanize($job.PSEndTime - $job.PSBeginTime, 2)))
        Remove-Item -Path $logFile -Force
    }
    finally {
        & net use O: /DELETE /Y
    }
}