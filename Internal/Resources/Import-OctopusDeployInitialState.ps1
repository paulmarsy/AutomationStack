function Import-OctopusDeployInitialState {
    Write-Host 'Initialising Azure VM Custom Script Extension...'

    try {
        $credential = New-Object System.Management.Automation.PSCredential ($CurrentContext.Get('StackResourcesName'), (ConvertTo-SecureString $CurrentContext.Get('StackResourcesKey') -AsPlainText -Force))
        New-PSDrive -Name O -PSProvider FileSystem -Root "\\$($CurrentContext.Get('StackResourcesName')).file.core.windows.net\octopusdeploy"  -Credential $credential | Out-Null
        
        $Argument = 'CustomScript.{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
        $logFile = 'O:\{0}' -f $Argument
        $logPosition = 0
        New-Item -Path $logFile -ItemType File | Out-Null

        $azureprofile = [System.IO.Path]::GetTempFileName()
        Save-AzureRmProfile -Path $azureprofile -Force

        $job = Start-Job -ScriptBlock {
            param($SubscriptionId, $AzureProfile, $ResourceGroupName, $Location, $VMName, $Name, $StorageAccountName, $StorageAccountKey, $FileName, $ContainerName, $Run, $Argument)
            Select-AzureRmProfile -Profile $AzureProfile
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId

            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -Name $Name -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -FileName $FileName -ContainerName $ContainerName -Run $Run -ForceRerun (Get-Date).Ticks -Argument $Argument
            Remove-Item -Path $AzureProfile -Force | Out-Null
        } -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureprofile, $CurrentContext.Get('OctopusRg'), $CurrentContext.Get('AzureRegion'), $CurrentContext.Get('OctopusVMName'), "OctopusImport", $CurrentContext.Get('StackResourcesName'), $CurrentContext.Get('StackResourcesKey'), "OctopusImport.ps1", "scripts", 'OctopusImport.ps1', $Argument)

        do {
            Start-Sleep 1
            Get-Content -Path $logFile -ErrorAction Ignore | Select-Object -Skip $logPosition | % { $logPosition++; $_ | Out-Host }
        } while ($job.State -eq 'Running')
        if ($job.State -ne 'Completed') {
            $job | Receive-Job | Out-Host
        }
        Write-Host
        Write-Host ('Custom Script Extension finished with state: {0} after {1}' -f $job.State, ([Humanizer.TimeSpanHumanizeExtensions]::Humanize($job.PSEndTime - $job.PSBeginTime, 2)))
        $job | Remove-Job
    }
    finally {
        Remove-PSDrive -Name O -Force
    }
}