if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

Update-DscConfiguration -Wait -Verbose *>> 'C:\CustomScriptLogs\DSC-Update.log'

& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>> 'C:\CustomScriptLogs\Octopus-Import.log'
& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{Password} --overwrite *>> 'C:\CustomScriptLogs\Octopus-Import.log'
& net use O: /DELETE *>> 'C:\CustomScriptLogs\Octopus-Import.log'