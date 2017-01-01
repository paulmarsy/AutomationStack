& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" service --stop

& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey}

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{Password} --overwrite
& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" admin --username=#{Username} --password=#{Password}

& net use O: /DELETE

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" service --start