if (Test-Path $ArchivePath) {
    Remove-Item $ArchivePath -Force
}
Compress-Archive -Path $ExportPath -DestinationPath $ArchivePath -CompressionLevel Fastest
