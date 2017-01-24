Remove-Item C:\Octopus\Tentacle.config -Force
Start-DscConfiguration -UseExisting -verbose -wait