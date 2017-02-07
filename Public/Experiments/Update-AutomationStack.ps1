function Update-AutomationStack {
    param(
        $GitHubAccount = 'paulmarsy',
        $Path = (Join-Path $PSScriptRoot '..\..\' | Get-Item | % FullName)
    )

    $gitRepoPath = Join-Path $Path '.git'
    if (Test-Path $gitRepoPath) {
        Write-Warning 'Git repository found, update using Git functionality'
    } else {
        $tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'zip')
        Write-Output "Downloading AutomationStack archive from GitHub to $tempFile..."
        (New-Object System.Net.WebClient).DownloadFile("https://github.com/$GitHubAccount/AutomationStack/archive/master.zip", $tempFile)

        Get-ChildItem -Path $Path -Exclude @('Deployments','Temp') -Directory | Remove-Item -Recurse -Force
        Remove-Item -Path (Join-Path $Path 'AutomationStack.ps?1') -Force
 
        Write-Output 'Extracting archive...'
        Expand-Archive -Path $tempFile -DestinationPath $Path -Force
        Move-Item -Path (Join-Path $Path 'AutomationStack-master\*') -Destination $Path -Force
    }

    Sync-AutomationStackModule
}