try {
    & net use O: \\#{StorageAccountName}.file.core.windows.net\octopusdeploy /USER:"#{StorageAccountName}" "#{StorageAccountKey}" *>&1 | Write-Log

    "{0}[ Stopping Octopus Service ]{0}" -f ("-"*36) | Write-Log
    Stop-Service OctopusDeploy -Force -Verbose *>&1 | Write-Log
    if ((Get-Service OctopusDeploy | % Status) -eq "Running") {
        Stop-Process -Name Octopus.Server -Force -Verbose *>&1 | Write-Log
    }

    "{0}[ Starting Octopus Import ]{0}" -f ("-"*36) | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\OctopusDeploy" --password="#{StackAdminPassword}" --overwrite *>&1 | Write-Log
    if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Migrator" }

    "{0}[ Configuring Octopus Authentication ]{0}" -f ("-"*31) | Write-Log
    $extensionsDir = Join-Path $env:ProgramData 'Octopus\CustomExtensions'
    if (!(Test-Path $extensionsDir)) {
        New-Item -ItemType Directory -Path $extensionsDir | Out-Null 
    }
    [System.Net.WebClient]::new().DownloadFile('https://github.com/paulmarsy/OctopusApiKeyAuthenticationProvider/raw/binaries/OctopusApiKeyAuthenticationProvider.dll', (Join-Path $extensionsDir 'OctopusApiKeyAuthenticationProvider.dll'))
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" configure --console --usernamePasswordIsEnabled=true *>&1 | Write-Log
    if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server" }
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" configure --console --apiKeyAuthEnabled=true *>&1 | Write-Log
    if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server" }

    "{0}[ Starting Octopus Service ]{0}" -f ("-"*36) | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" service --console --start *>&1 | Write-Log
    if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Octopus Server" }

    "{0}[ Publishing Octopus Deploy Packages ]{0}" -f ("-"*31) | Write-Log
    $totalPackages = Invoke-WebRequest -Uri '#{OctopusHostHeader}/api/serverstatus/nuget' -Headers @{ "X-Octopus-ApiKey" = '#{ApiKey}' } -UseBasicParsing -ErrorAction Stop | % Content | ConvertFrom-Json | % TotalPackages
    @('ARMCustomScripts','ARMTemplates','AutomationStackScripts') | % {
        $totalPackages++
        $versionedFile = "${env:TEMP}\1.0.${_}.${totalPackages}.zip"
        Write-Log "Publishing package $versionedFile to feed... "
        
        Copy-Item -Path "O:\${_}.zip" -Destination $versionedFile
        
        [System.Net.WebClient]::new().UploadFile(('#{OctopusHostHeader}/api/packages/raw?apiKey=#{ApiKey}', $versionedFile) | Out-Null
    }

}
finally {
    & net use O: /DELETE /Y *>&1 | Write-Log
}