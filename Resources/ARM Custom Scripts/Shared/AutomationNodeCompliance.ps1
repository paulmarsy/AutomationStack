"{0}[ Waiting for Local Configuration Manager ]{0}" -f ("-"*28) | Write-Log
$lcm = Get-DscLocalConfigurationManager
while ($lcm.LCMState -eq 'Busy') {
    "DSC Local Configuration Manager state is $($lcm.LCMState); waiting..." | Write-Log
    Start-Sleep -Seconds 5
    $lcm = Get-DscLocalConfigurationManager
}

"{0}[ Updating DSC ]{0}" -f ("-"*42) | Write-Log
Update-DscConfiguration -Verbose -Wait *>&1 | Write-Log

"{0}[ Starting DSC ]{0}" -f ("-"*42) | Write-Log
Start-DscConfiguration -UseExisting -Wait -Verbose *>&1 | Write-Log

"{0}[ Finished DSC ]{0}" -f ("-"*42) | Write-Log
$dscStatus = Get-DscConfigurationStatus | % Status
"DSC Configuration Status: $dscStatus" | Write-Log
if ($dscStatus -ne 'Success') {
    'Resources in desired state:' | Write-Log
    Get-DscConfigurationStatus | % ResourcesInDesiredState | % ResourceId | Write-Log
    'Resources NOT in desired state:' | Write-Log
    Get-DscConfigurationStatus | % ResourcesNotInDesiredState | % ResourceId | Write-Log
    'Errors:' | Write-Log
    Get-DscConfigurationStatus | % ResourcesNotInDesiredState | % { 
        "{0} {1} {0}" -f ("-"*20), $_.ResourceId | Write-Log
        $_.Error | Write-Log
    }
    throw (Get-DscConfigurationStatus | % Error)
}