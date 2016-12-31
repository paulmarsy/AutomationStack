& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeployrestore /u:#{StackResourcesName} #{StackResourcesKey}

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\OctopusDeploy Export" --password=#{Password} --overwrite

& net use O: /DELETE