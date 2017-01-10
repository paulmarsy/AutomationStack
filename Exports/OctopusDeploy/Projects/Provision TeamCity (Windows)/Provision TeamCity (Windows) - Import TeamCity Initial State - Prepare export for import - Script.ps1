Compress-Archive -Path "${ExportPath}\*" -DestinationPath $ArchivePath -CompressionLevel Fastest

New-Item -Path $JDBCDst -ItemType Directory
Copy-Item -Path $JDBCSrc -Destination $JDBCDst

[system.io.file]::WriteAllText($DatabaseConfig, ([system.io.file]::ReadAllText($DatabaseConfig, [system.text.encoding]::UTF8)), [system.text.encoding]::ASCII)