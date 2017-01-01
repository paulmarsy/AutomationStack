New-Item -ItemType Directory -Path $ExportPath
 
 if ($ProjectToExport -eq 'All') {
     & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" export --console --directory=$ExportPath --password=$ExportPassword
 } else {
    & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" partial-export --console --directory=$ExportPath --password=$ExportPassword  --ignore-deployments  --ignore-machines --ignore-tenants --project="$ProjectToExport" 
}