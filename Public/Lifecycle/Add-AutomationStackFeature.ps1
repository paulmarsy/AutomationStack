function Add-AutomationStackFeature { 
    param(
        [ValidateSet('Infrastructure','OctopusDeploy','TeamCity','VisualStudioTeamServices')]$Feature,
        [Parameter(DontShow)][switch]$DontJoin
    )

    $job = switch ($Feature) {
        'Infrastructure' {
            [AutomationStackJob]::Create('Infrastructure', $CurrentContext).AzureAuth().StorageContext().ResourceGroupDeployment('infrastructure').Start()
        }
        'OctopusDeploy' { 
            $context = Get-StackResourcesContext
            $octopusCustomScriptLogFile = 'OctopusDeploy.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))
            [AutomationStackJob]::Create('Octopus Deploy', $CurrentContext).AzureAuth().StorageContext().ResourceGroupDeployment('octopusdeploy', @{
                timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
                computeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
                computeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
                octopusDscJobId = [System.Guid]::NewGuid().ToString()
                octopusDscConfiguration = (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.ps1' -Context $context).ICloudBlob.DownloadText()
                octopusDscConfigurationData =  (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.json' -Context $context).ICloudBlob.DownloadText()
                octopusDscConnectionString = $CurrentContext.Get('OctopusConnectionString')
                octopusDscHostName = $CurrentContext.Get('OctopusHostName')
                octopusCustomScriptLogFile = $octopusCustomScriptLogFile 
            }).GetCustomScriptOutput($octopusCustomScriptLogFile).Start()
        }
    }
    if (!$DontJoin) {
        $job.Join()
    }
    return $job
}