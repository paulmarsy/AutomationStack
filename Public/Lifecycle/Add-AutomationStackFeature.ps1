function Add-AutomationStackFeature { 
    param(
        [ValidateSet('Infrastructure','OctopusDeploy','TeamCity','VisualStudioTeamServices')]$Feature,
        [Parameter(DontShow)][switch]$DontJoin
    )

    $jobBuilder = [JobBuilder]::Create($Feature, $CurrentContext).AzureAuth().StorageContext()
    $context = Get-StackResourcesContext
    switch ($Feature) {
        'Infrastructure' {            
            $runbooks = Get-AzureStorageBlob -Container runbooks -Context $context | % Name
            $jobBuilder.ResourceGroupDeployment('infrastructure', @{
                runbookSasToken = (New-AzureStorageContainerSASToken -Name runbooks -Permission r -ExpiryTime (Get-Date).AddHours(1) -Context $context)
                runbookLibPaths = @($runbooks | ? { $_.StartsWith('Library/') } | % { [string]$_ })
                runbookLibNames = @($runbooks | ? { $_.StartsWith('Library/') } | % { [string][System.IO.Path]::GetFileNameWithoutExtension($_) })
                runbookPaths = @($runbooks | ? { -not $_.StartsWith('Library/') } | % { [string]$_ })
                runbookNames = @($runbooks | ? { -not $_.StartsWith('Library/') } | % { [string][System.IO.Path]::GetFileNameWithoutExtension($_) })
            }).WaitForDeployment()
        }
        'OctopusDeploy' { 
            $octopusCustomScriptLogFile = 'OctopusDeploy.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))
            $jobBuilder.ResourceGroupDeployment('octopusdeploy', @{
                timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
                computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
                computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
                octopusDscJobId = [System.Guid]::NewGuid().ToString()
                octopusDscConfiguration = (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.ps1' -Context $context).ICloudBlob.DownloadText()
                octopusDscConfigurationData =  (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.json' -Context $context).ICloudBlob.DownloadText()
                octopusDscConnectionString = $CurrentContext.Get('OctopusConnectionString')
                octopusDscHostName = $CurrentContext.Get('OctopusHostName')
                octopusCustomScriptLogFile = $octopusCustomScriptLogFile 
            }).WaitForDeployment().GetCustomScriptOutput($octopusCustomScriptLogFile).Runbook('Enable-AzureDiskEncryption', @{
                name = 'Octopus'
            }
        }
        'TeamCity' {
            $teamcityCustomScriptLogFile = 'TeamCity.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))
            $jobBuilder.ResourceGroupDeployment('teamcity', @{
                timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
                computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
                computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
                teamcityDscJobId = [System.Guid]::NewGuid().ToString()
                teamcityDscConfiguration = (Get-AzureStorageBlob -Container dsc -Blob 'TeamCity.ps1' -Context $context).ICloudBlob.DownloadText()
                teamcityDscConfigurationData = (Get-AzureStorageBlob -Container dsc -Blob 'TeamCity.json' -Context $context).ICloudBlob.DownloadText()
                teamcityDscTentacleRegistrationUri = $CurrentContext.Get('OctopusHostHeader')
                teamcityDscTentacleRegistrationApiKey = $CurrentContext.Get('ApiKey')
                teamcityDscHostHeader = $CurrentContext.Get('TeamCityHostHeader')
                teamcityCustomScriptLogFile = $teamcityCustomScriptLogFile
            }).WaitForDeployment().GetCustomScriptOutput($teamcityCustomScriptLogFile).Runbook('Enable-AzureDiskEncryption', @{
                name = 'TeamCity'
            }
        }
    }
    if (!$DontJoin -and $Feature -in @('OctopusDeploy','TeamCity')) {
        $jobBuilder.WaitForRunbook()
    }
    $job = $jobBuilder.Start()
    if (!$DontJoin) {
        $job.Join()
    }
    return $job
}