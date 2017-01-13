if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$logFile = 'C:\CustomScriptLogs\{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))

# Force DSC to run... a hack as DSC isn't reliably reporting node compliance 
Remove-DscConfigurationDocument -Stage Pending -Force *>> $logFile
Remove-DscConfigurationDocument -Stage Current -Force *>> $logFile
Update-DscConfiguration -Wait -Verbose *>> $logFile

# Octopus Deploy Initial Data Import
& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>> $logFile

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{StackAdminPassword} --overwrite *>> $logFile

Copy-Item -Path $logFile -Destination O:\CustomScript.log -Force *>> $logFile

& net use O: /DELETE *>> $logFile