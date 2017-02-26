param($LogFileName, $StorageAccountName, $StorageAccountKey)

$octopusDeployStateFile =  "$($env:SystemDrive)\Octopus\firstrun.statefile"     
if (Test-Path $octopusDeployStateFile) { throw 'Octopus Deploy Configuration Already Run' }
try {
    . (Join-Path -Resolve $PSScriptRoot '\Shared\CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    & (Join-Path -Resolve $PSScriptRoot '\Shared\AutomationNodeCompliance.ps1')
    & (Join-Path -Resolve $PSScriptRoot '\OctopusDeploy\OctopusImport.ps1')

    "{0}[ Finished ]{0}" -f ("-"*44) | Write-Log
    [System.IO.FIle]::WriteAllText($octopusDeployStateFile, (Get-Date -Format 'u'), [System.Text.Encoding]::ASCII)
}
finally {
    Send-SignalTerminate
}