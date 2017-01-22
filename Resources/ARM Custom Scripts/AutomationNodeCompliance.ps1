param($LogFileName, $StorageAccountName, $StorageAccountKey)
. (Join-Path -Resolve $PSScriptRoot 'CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

"{0}[ Waiting for Local Configuration Manager ]{0}" -f ("-"*28) | Write-Log
$lcm = Get-DscLocalConfigurationManager
while ($lcm.LCMState -notin @('Idle','PendingConfiguration')) {
    "DSC Local Configuration Manager state is $($lcm.LCMState); waiting..." | Write-Log
    Start-Sleep -Seconds 10
    $lcm = Get-DscLocalConfigurationManager
}

"{0}[ Starting DSC ]{0}" -f ("-"*42) | Write-Log
Update-DscConfiguration -Verbose -Wait *>&1 | Write-Log
Start-DscConfiguration -UseExisting -Wait -Verbose *>&1 | Write-Log

"{0}[ Finished ]{0}" -f ("-"*44) | Write-Log