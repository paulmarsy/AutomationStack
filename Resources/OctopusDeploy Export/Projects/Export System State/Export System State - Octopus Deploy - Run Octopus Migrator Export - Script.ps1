New-Item -ItemType Directory -Path $OctopusExportPath
 
 if ($ProjectToExport -eq 'All') {
     & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" export --console --directory=$OctopusExportPath --password=$ExportPassword
 } else {
    & "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" partial-export --console --directory=$OctopusExportPath --password=$ExportPassword  --ignore-deployments  --ignore-machines --ignore-tenants --project="$ProjectToExport" 
}