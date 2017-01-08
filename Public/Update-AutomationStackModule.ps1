function Update-AutomationStackModule {
    param(
        $GitHubAccount = 'paulmarsy',
        $Path = (Join-Path $PSScriptRoot '..\' | Get-Item | % FullName)
    )
    $gitRepoPath = Join-Path $PSScriptRoot '..\.git'
    if (Test-Path $gitRepoPath) {
        Write-Warning 'Git repository found, update using Git functionality'
        return
    }
    Write-Output 'Downloading AutomationStack archive from GitHub...'
    $download = Invoke-WebRequest -Verbose -UseBasicParsing -Uri "https://github.com/$GitHubAccount/AutomationStack/archive/master.zip"
    $tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'zip')
    Write-Output "Saving file to ${tempFile}"
    Set-Content -Path $tempFile -Value $download.Content -Force -Encoding Byte
    Write-Output 'Extracting archive...'

    Expand-Archive -Path $tempFile -DestinationPath $Path -Force

    Remove-Item -Path (Join-Path $Path 'Internal') -Recurse -Force
    Remove-Item -Path (Join-Path $Path 'Public') -Recurse -Force
    Remove-Item -Path (Join-Path $Path 'Resources') -Recurse -Force
    Remove-Item -Path (Join-Path $Path 'AutomationStack.ps?1') -Force
    Move-Item -Path (Join-Path $Path 'AutomationStack-master\*') -Destination $Path -Force
    Remove-Module AutomationStack -Force
    if ($null -ne $CurrentContext) {
        Import-Module (Join-Path $Path 'AutomationStack.psd1') -Force -ArgumentList $CurrentContext.Get('UDP')
    } else {
        Import-Module (Join-Path $Path 'AutomationStack.psd1') -Force
    }
}