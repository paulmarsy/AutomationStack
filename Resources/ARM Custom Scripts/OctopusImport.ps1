Start-Transcript -path D:\OctopusImport.log -Append

Update-DscConfiguration -Wait

& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey}

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{Password} --overwrite

& net use O: /DELETE

Stop-Transcript