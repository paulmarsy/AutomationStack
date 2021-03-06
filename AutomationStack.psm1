param([string]$UDP)

$script:ErrorActionPreference = 'Stop'

$script:DataImportPath = Join-Path -Resolve $PSScriptRoot 'Data Import' | Convert-Path
$script:ResourcesPath = Join-Path -Resolve $PSScriptRoot 'Resources' | Convert-Path
$script:ScriptsPath = Join-Path -Resolve $ResourcesPath 'Scripts' | Convert-Path

$DeploymentsPath = Join-Path $PSScriptRoot 'Deployments'
if (!(Test-Path $DeploymentsPath)) { New-Item -ItemType Directory -Path $DeploymentsPath | Out-Null }
$script:DeploymentsPath = Get-Item -Path $DeploymentsPath | % FullName

$TempPath = Join-Path $PSScriptRoot 'Temp'
if (!(Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath | Out-Null }
$script:TempPath = Get-Item -Path $TempPath | % FullName

$script:TotalDeploymentStages = 8

if (Test-Path (Join-Path $PSScriptRoot 'Resources\AzureRest\AzureRest.psd1')) {
    try {
        Import-Module (Join-Path $PSScriptRoot 'Resources\AzureRest\AzureRest.psd1') -Force
    }
    catch {
        Write-Warning "AzureRest module was not loaded: $_"
    }
}
. (Join-Path $PSScriptRoot 'Classes\Loader.ps1')
Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Internal') -Recurse | % { . $_.FullName }
Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Public') -Recurse | % { . $_.FullName; Export-ModuleMember -Function $_.BaseName }
Set-ServicePointManager

if ($UDP) {
    Write-Host -ForegroundColor DarkGreen "Loading deployment context: $UDP"
    $script:CurrentContext = New-Object Octosprache $UDP
} else {
    $script:CurrentContext = $null
}