param(
    $GitHubAccount = 'paulmarsy',
    $Path = (Join-Path $PWD.ProviderPath 'AutomationStack')
)

$ErrorActionPreference = 'Stop'

$padding = ' '*(($Host.UI.RawUI.BufferSize.Width - 90) / 2)
Write-Host
Write-Host -N $padding; Write-Host -B White -F Black '     ___         __                        __  _                _____ __             __   '
Write-Host -N $padding; Write-Host -B White -F Black '    /   | __  __/ /_____  ____ ___  ____ _/ /_(_)___  ____     / ___// /_____ ______/ /__ '
Write-Host -N $padding; Write-Host -B White -F Black '   / /| |/ / / / __/ __ \/ __ `__ \/ __ `/ __/ / __ \/ __ \    \__ \/ __/ __ `/ ___/ //_/ '
Write-Host -N $padding; Write-Host -B White -F Black '  / ___ / /_/ / /_/ /_/ / / / / / / /_/ / /_/ / /_/ / / / /   ___/ / /_/ /_/ / /__/ ,<    '
Write-Host -N $padding; Write-Host -B White -F Black ' /_/  |_\__,_/\__/\____/_/ /_/ /_/\__,_/\__/_/\____/_/ /_/   /____/\__/\__,_/\___/_/|_|   '
Write-Host -N $padding; Write-Host -B White -F Black '                                                                                          '
Write-Host

if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Error 'AutomationStack requires PowerShell 5 to begin. Go to ''Download WMF 5.0'' at https://msdn.microsoft.com/en-us/powershell' }

if (Test-Path $Path) {
    Write-Warning 'Previous AutomationStack directory exists...'
    Remove-Item $Path -Recurse -Force -ErrorAction Ignore
}

$tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'zip')
Write-Output "Downloading AutomationStack archive from GitHub to $tempFile..."
(New-Object System.Net.WebClient).DownloadFile("https://github.com/$GitHubAccount/AutomationStack/archive/master.zip", $tempFile)

Write-Output 'Extracting archive...'
Expand-Archive -Path $tempFile -DestinationPath $Path -Force
Move-Item -Path (Join-Path $Path 'AutomationStack-master\*') -Destination $Path -Force

$moduleManifest = Join-Path $Path 'AutomationStack.psd1'
if (!(Test-Path $moduleManifest)) { Write-Error 'Unable to find the AutomationStack module' }

Write-Output 'AutomationStack aquired, importing module & starting deployment...'
Import-Module $moduleManifest -Force
AutomationStack\New-AutomationStack