function Start-AutomationStackFeature {
    param(
        [ValidateSet('TeamCity')]$Feature
    )
    if ($CurrentContext.Get('DeploymentComplete') -ne $true) {
        Write-Host -ForegroundColor Red "ERROR: Core AutomationStack Environment must be provisioned before additional features can be used. Try 'New-AutomationStack'"
        return
    }
    Install-Package OctopusTools -Source https://www.nuget.org/api/v2 -Force -Destination $TempPath -RequiredVersion '4.5.0'
    $octo = Join-Path $TempPath 'OctopusTools.4.5.0\tools\Octo.exe' -Resolve
    $defaultArgs = @(
        ('--server="{0}"' -f $CurrentContext.Get('OctopusHostHeader'))
        '--debug'
        ('--apikey={0}' -f $CurrentContext.Get('ApiKey'))
    )
    $teamcityVer = '10.0.4'
    & $octo create-release @defaultArgs --project="Provision TeamCity (Windows)" --packageversion=$teamcityVer --releaseNumber=$teamcityVer
}
