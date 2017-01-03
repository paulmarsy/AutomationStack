if (Test-Path $ExportPath) {
    Remove-Item $ExportPath -Recurse -Force
}
New-Item -ItemType Directory -Path $ExportPath

& net use T: \\$StackResourcesName.file.core.windows.net\dsc /u:$StackResourcesName $StackResourcesKey
Copy-Item -Path T:\* -Destination $ExportPath -Recurse
& net use T: /DELETE
