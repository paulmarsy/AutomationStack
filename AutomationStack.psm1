$ResourcesPath = Join-Path -Resolve $PSScriptRoot 'Resources' | Convert-Path
$DeploymentsPath = Join-Path -Resolve $PSScriptRoot 'Deployments' | Convert-Path
if (!(Test-Path $DeploymentsPath)) {
    New-Item -ItemType Directory -Path $DeploymentsPath | Out-Null
}
$TempPath = Join-Path -Resolve $PSScriptRoot 'Temp' | Convert-Path
if (!(Test-Path $TempPath)) {
    New-Item -ItemType Directory -Path $TempPath | Out-Null
}
$ConcurrentTaskCount = 8
$CurrentContext = $null


Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Internal') -Recurse | % {
	. "$($_.FullName)"
}

Get-ChildItem -File -Filter *.ps1 -Path (Join-Path $PSScriptRoot 'Public') -Recurse | % {
	. "$($_.FullName)"	
	Export-ModuleMember -Function $_.BaseName
}