$ErrorActionPreference = 'Stop'

$script:ResourcesPath = Join-Path -Resolve $PSScriptRoot 'Resources' | Convert-Path
$DeploymentsPath = Join-Path $PSScriptRoot 'Deployments'
if (!(Test-Path $DeploymentsPath)) {
    New-Item -ItemType Directory -Path $DeploymentsPath | Out-Null
}
$script:DeploymentsPath = Get-Item -Path $DeploymentsPath | % FullName
$TempPath = Join-Path $PSScriptRoot 'Temp'
if (!(Test-Path $TempPath)) {
    New-Item -ItemType Directory -Path $TempPath | Out-Null
}
$script:TempPath = Get-Item -Path $TempPath | % FullName
$script:ConcurrentTaskCount = 8
$script:CurrentContext = $null


Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Internal') -Recurse | % {
	. "$($_.FullName)"
}

Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Public') -Recurse | % {
	. "$($_.FullName)"	
	Export-ModuleMember -Function $_.BaseName
}

[Octosprache]::Init()