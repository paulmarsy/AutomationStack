function Import-OctopusDeployInitialState {
    Write-Host 'Initialising Azure VM Custom Script Extension...'

    $stackresources = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
    
    $logFile = 'CustomScript.{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
    $localLogFile = Join-Path $TempPath $logFile
    $logPosition = 0
    New-Item -Path $localLogFile -ItemType File | Out-Null
    Set-AzureStorageFileContent -ShareName octopusdeploy -Source $localLogFile -Path $logFile -Force -Context $stackresources

    $azureprofile = [System.IO.Path]::GetTempFileName()
    Save-AzureRmProfile -Path $azureprofile -Force

    $job = Start-Job -ScriptBlock {
        param($SubscriptionId, $AzureProfile, $ResourceGroupName, $Location, $VMName, $Name, $StorageAccountName, $StorageAccountKey, $FileName, $ContainerName, $Run, $Argument)
        Select-AzureRmProfile -Profile $AzureProfile
        Select-AzureRmSubscription  -SubscriptionId $SubscriptionId

        Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -Name $Name -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -FileName $FileName -ContainerName $ContainerName -Run $Run -ForceRerun (Get-Date).Ticks -Argument $Argument
        Remove-Item -Path $AzureProfile -Force | Out-Null
    } -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureprofile, $CurrentContext.Get('OctopusRg'), $CurrentContext.Get('AzureRegion'), $CurrentContext.Get('OctopusVMName'), "OctopusImport", $CurrentContext.Get('StackResourcesName'), $CurrentContext.Get('StackResourcesKey'), "OctopusImport.ps1", "scripts", 'OctopusImport.ps1', $logFile)

    $ProgressPreference = 'SilentlyContinue'
    do {
        Start-Sleep 1
        Get-AzureStorageFileContent -ShareName octopusdeploy -Path $logFile -Context $stackresources -Destination $localLogFile -Force
        Get-Content -Path $localLogFile | Select-Object -Skip $logPosition | % { $logPosition++; $_ | Out-Host }
    } while ($job.State -eq 'Running')
    $ProgressPreference = 'Continue'
    if ($job.State -ne 'Completed') {
        $job | Receive-Job | Out-Host
    }
    Write-Host
    Write-Host ('Custom Script Extension finished with state: {0} after {1}' -f $job.State, ([Humanizer.TimeSpanHumanizeExtensions]::Humanize($job.PSEndTime - $job.PSBeginTime, 2)))
    $job | Remove-Job
}