param($LogFileName, $StorageAccountName, $StorageAccountKey)
. (Join-Path -Resolve $PSScriptRoot 'CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

try {
    & net use O: \\#{StorageAccountName}.file.core.windows.net\octopusdeploy /USER:"#{StorageAccountName}" "#{StorageAccountKey}" *>&1 | Write-Log

    "{0}[ Stopping Octopus Service ]{0}" -f ("-"*36) | Write-Log
    Stop-Service OctopusDeploy -Force -Verbose *>&1 | Write-Log
    if ((Get-Service OctopusDeploy | % Status) -eq "Running") {
        Stop-Process -Name Octopus.Server -Force -Verbose *>&1 | Write-Log
    }

    "{0}[ Starting Octopus Import ]{0}" -f ("-"*36) | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password="#{StackAdminPassword}" --overwrite *>&1 | Write-Log
    
    "{0}[ Configuring Octopus Authentication ]{0}" -f ("-"*31) | Write-Log
    $extensionsDir = Join-Path $env:ProgramData 'Octopus\CustomExtensions'
    if (!(Test-Path $extensionsDir)) {
        New-Item -ItemType Directory -Path $extensionsDir | Out-Null 
    }
    [System.Net.WebClient]::new().DownloadFile('https://github.com/paulmarsy/OctopusApiKeyAuthenticationProvider/raw/binaries/OctopusApiKeyAuthenticationProvider.dll', (Join-Path $extensionsDir 'OctopusApiKeyAuthenticationProvider.dll'))
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" configure --console --usernamePasswordIsEnabled=true *>&1 | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" configure --console --apiKeyAuthEnabled=true *>&1 | Write-Log

    "{0}[ Starting Octopus Service ]{0}" -f ("-"*36) | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" service --console --start *>&1 | Write-Log

    "{0}[ Finished ]{0}" -f ("-"*44) | Write-Log
}
finally {
    & net use O: /DELETE /Y *>&1 | Write-Log
}