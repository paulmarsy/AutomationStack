& net use T: \\$StackResourcesName.file.core.windows.net\teamcity /u:$StackResourcesName $StackResourcesKey
Copy-Item -Path T:\* -Destination $ExportPath -Recurse
& net use T: /DELETE
