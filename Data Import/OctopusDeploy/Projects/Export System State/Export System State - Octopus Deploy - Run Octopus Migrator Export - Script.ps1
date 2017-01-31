New-Item -ItemType Directory -Path $OctopusExportPath
 
& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" export --console --directory=$OctopusExportPath --password=$ExportPassword
