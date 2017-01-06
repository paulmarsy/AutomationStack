function Start-AutomationStackFeature {
    param(
        [ValidateSet('TeamCity', 'EnableRDP')]$Feature
    )
    if ($CurrentContext.Get('DeploymentComplete') -ne $true) {
        Write-Host -ForegroundColor Red "ERROR: Core AutomationStack Environment must be provisioned before additional features can be used. Try 'New-AutomationStack'"
        return
    }
    $octo = Join-Path $TempPath 'OctopusTools.4.5.0\tools\Octo.exe'
    if (!(Test-Path $octo)) {
        Install-Package OctopusTools -Source https://www.nuget.org/api/v2 -Force -Destination $TempPath -RequiredVersion '4.5.0' | Out-Null
    }
    
    $defaultArgs = @(
        ('--server="{0}"' -f $CurrentContext.Get('OctopusHostHeader'))
        ('--apikey={0}' -f $CurrentContext.Get('ApiKey'))
        '--progress'
        '--waitfordeployment'
        '--deployto="Microsoft Azure"'
    )
    switch ($Feature) {
        'EnableRDP' { $args = @('--project="Enable Remote Desktop"')  }
        'TeamCity' { $teamcityVer = '10.0.4'; $args = @('--project="Provision TeamCity (Windows)"', "--packageversion=$teamcityVer", "--releaseNumber=$teamcityVer") }
    }
 
    & $octo create-release @defaultArgs  @args
}
