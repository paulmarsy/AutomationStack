Write-Output 'Waiting for Local Configuration Manager'
$lcm = Get-DscLocalConfigurationManager
while ($lcm.LCMState -notin @('Idle','PendingConfiguration')) {
    Write-Output "DSC Local Configuration Manager state is $($lcm.LCMState); waiting..."
    Start-Sleep -Seconds 10
    $lcm = Get-DscLocalConfigurationManager
}

Write-Output 'Starting DSC'
Update-DscConfiguration -Verbose -Wait
Start-DscConfiguration -UseExisting -Wait -Verbose

