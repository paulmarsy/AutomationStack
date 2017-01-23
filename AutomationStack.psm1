param(
    [string]$UDP
)

$script:ErrorActionPreference = 'Stop'

$script:ExportsPath = Join-Path -Resolve $PSScriptRoot 'Exports' | Convert-Path
$script:ResourcesPath = Join-Path -Resolve $PSScriptRoot 'Resources' | Convert-Path
$script:ScriptsPath = Join-Path -Resolve $ResourcesPath 'Scripts' | Convert-Path

$DeploymentsPath = Join-Path $PSScriptRoot 'Deployments'
if (!(Test-Path $DeploymentsPath)) { New-Item -ItemType Directory -Path $DeploymentsPath | Out-Null }
$script:DeploymentsPath = Get-Item -Path $DeploymentsPath | % FullName

$TempPath = Join-Path $PSScriptRoot 'Temp'
if (!(Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath | Out-Null }
$script:TempPath = Get-Item -Path $TempPath | % FullName

$script:ConcurrentNetTasks = 10
$script:TotalDeploymentStages = 10


. (Join-Path $PSScriptRoot 'Classes\Loader.ps1')
Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Internal') -Recurse | % { . "$($_.FullName)" }
Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Public') -Recurse | % { . "$($_.FullName)"; Export-ModuleMember -Function $_.BaseName }
Set-ServicePointManager

if ($UDP) {
    Write-Host "Loading deployment context: $UDP"
    $script:CurrentContext = New-Object Octosprache $UDP
} else {
    $script:CurrentContext = $null
}