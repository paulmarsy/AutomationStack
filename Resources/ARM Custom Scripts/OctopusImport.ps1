if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$logFile = 'C:\CustomScriptLogs\{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
(Get-Date).ToString() | Tee-Object -FilePath $logFile -Append

$lcm = Get-DscLocalConfigurationManager
while ($lcm.LCMState -ne 'Idle') {
    "DSC Local Configuration Manager state is $($lcm.LCMState); waiting 10 seconds..." | Tee-Object -FilePath $logFile -Append
    Start-Sleep -Seconds 10
    $lcm = Get-DscLocalConfigurationManager
}
"{0}Starting DSC{0}" -f ("-"*40) | Tee-Object -FilePath $logFile -Append
Update-DscConfiguration -Verbose -Wait *>&1 | Tee-Object -FilePath $logFile -Append
Start-DscConfiguration -UseExisting -Wait -Verbose *>&1 | Tee-Object -FilePath $logFile -Append



"{0}Starting Octopus Import{0}" -f ("-"*40) | Tee-Object -FilePath $logFile -Append
try {
    & net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>&1 | Tee-Object -FilePath $logFile -Append

    & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{StackAdminPassword} --overwrite *>&1 | Tee-Object -FilePath $logFile -Append

    Copy-Item -Path $logFile -Destination O:\CustomScript.log -Force *>&1 | Tee-Object -FilePath $logFile -Append
}
finally {
    & net use O: /DELETE *>&1 | Tee-Object -FilePath $logFile -Append
}