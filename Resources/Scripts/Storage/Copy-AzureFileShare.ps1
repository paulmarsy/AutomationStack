param($StorageAccountName, $StorageAccountKey, $FileShareName, $LocalPath)

try {
    & net use F: \\$StorageAccountName.file.core.windows.net\$FileShareName /persistent:no /u:$StorageAccountName $StorageAccountKey
    if (!(Test-Path $LocalPath)) {
         New-Item -ItemType Directory -Path $LocalPath | Out-Null
    }
    Copy-Item -Path 'F:\*' -Destination $LocalPath -Recurse -Force
}
finally {
    & net use F: /DELETE /Y
}