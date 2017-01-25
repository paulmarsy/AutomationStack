param($LogFileName, $StorageAccountName, $StorageAccountKey)
. (Join-Path -Resolve $PSScriptRoot 'CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

try {
    & net use O: \\#{StorageAccountName}.file.core.windows.net\octopusdeploy /USER:"#{StorageAccountName}" "#{StorageAccountKey}" *>&1 | Write-Log

    "{0}[ Starting Octopus Import ]{0}" -f ("-"*36) | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password="#{StackAdminPassword}" --overwrite *>&1 | Write-Log
    & "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe" configure --console --usernamePasswordIsEnabled=true
    "{0}[ Finished ]{0}" -f ("-"*44) | Write-Log
}
finally {
    & net use O: /DELETE /Y *>&1 | Write-Log
}