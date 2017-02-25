function Add-AutomationStackFeature { 
    param(
        [ValidateSet('Infrastructure','OctopusDeploy','TeamCity','VisualStudioTeamServices')]$Feature,
        [Parameter(DontShow)][switch]$DontJoin
    )

    $job = switch ($Feature) {
        'Infrastructure' { [AutomationStackJob]::Runbook('DeployInfrastructure', @{}) }
        'OctopusDeploy' { [AutomationStackJob]::Runbook('DeployOctopusDeploy', @{
                                ComputeVmShutdownStatus = $CurrentContext.Get('ComputeVmShutdownTask.Status')
                                ComputeVmShutdownTime = $CurrentContext.Get('ComputeVmShutdownTask.Time')
                                OctopusDscConnectionString = $CurrentContext.Get('OctopusConnectionString')
                                OctopusDscHostName = $CurrentContext.Get('OctopusHostName')
                            }) }
        'VisualStudioTeamServices' { [AutomationStackJob]::ResourceGroupDeployment('vsts', @{}) }
    }
    $job.Start()
    if (!$DontJoin) {
        $job.Join()
    }
    return $job
}