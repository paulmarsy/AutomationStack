param(
    $GitHubAccount = 'paulmarsy',
    $Path = (Join-Path $PWD.ProviderPath 'AutomationStack')
)

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error 'AutomationStack requires PowerShell 5 to begin. Go to ''Download WMF 5.0'' at https://msdn.microsoft.com/en-us/powershell'
    return
}

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
if (!(Test-Path $moduleManifest)) {
    Write-Error 'Unable to find the AutomationStack module'
    return
}

Write-Output 'AutomationStack aquired, importing module & starting deployment...'
Import-Module $moduleManifest -Force
AutomationStack\New-AutomationStack