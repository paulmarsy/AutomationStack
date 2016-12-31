New-Item -ItemType Directory -Path $ExportPath

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" export --console --directory=$ExportPath --password=$ExportPassword
