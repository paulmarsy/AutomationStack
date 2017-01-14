if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$logFile = 'C:\CustomScriptLogs\{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))
(Get-Date).ToString()  *>> $logFile

# Until DSC Compliance is reliable
Add-Content -Path $logFile -Value ("{0}`nStarting DSC Run`n{0}`n" -f ("-"*80))
Remove-DscConfigurationDocument -Stage Pending -Force -Verbose  *>> $logFile
Update-DscConfiguration -Verbose -Wait *>> $logFile
Start-DscConfiguration -UseExisting -Wait -Verbose  *>> $logFile

# Octopus Deploy Initial Data Import
Add-Content -Path $logFile -Value ("{0}`nStarting Octopus Import`n{0}`n" -f ("-"*80))
& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>> $logFile

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{StackAdminPassword} --overwrite *>> $logFile

Copy-Item -Path $logFile -Destination O:\CustomScript.log -Force *>> $logFile

& net use O: /DELETE *>> $logFile