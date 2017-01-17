if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$localLogFile = 'C:\CustomScriptLogs\{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
$remoteLogFile = 'O:\CustomScript.log'
filter Write-Log {
    $entry = '[{0}] {1}: {2}' -f $env:COMPUTERNAME, (Get-Date).ToShortTimeString(), ($_ | Out-String)
    Add-Content -Path $localLogFile -Value $entry -NoNewline
    Add-Content -Path $remoteLogFile -Value $entry -NoNewline
}

try {
    & net use O: \\#{StackResourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>&1 | Write-Log

    (Get-Date).ToString() | Write-Log

    "{0}[ Waiting for Local Configuration Manager ]{0}" -f ("-"*28) | Write-Log
    $lcm = Get-DscLocalConfigurationManager
    while ($lcm.LCMState -ne 'Idle') {
        "DSC Local Configuration Manager state is $($lcm.LCMState); waiting..." | Write-Log
        Start-Sleep -Seconds 10
        $lcm = Get-DscLocalConfigurationManager
    }

    "{0}[ Starting DSC ]{0}" -f ("-"*42) | Write-Log
    Update-DscConfiguration -Verbose -Wait *>&1 | Write-Log
    Start-DscConfiguration -UseExisting -Wait -Verbose *>&1 | Write-Log

    "{0}[ Starting Octopus Import ]{0}" -f ("-"*36) | Write-Log
    & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{StackAdminPassword} --overwrite *>&1 | Write-Log
}
finally {
    & net use O: /DELETE *>&1 | Write-Log
}