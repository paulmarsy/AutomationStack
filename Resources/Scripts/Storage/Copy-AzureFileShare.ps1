param($StorageAccountName, $StorageAccountKey, $FileShareName, $LocalPath)

try {
    $credential = New-Object System.Management.Automation.PSCredential $StorageAccountName, (ConvertTo-SecureString $StorageAccountKey -AsPlainText -Force)
    New-PSDrive -Name F -PSProvider FileSystem -Root "\\$($StorageAccountName).file.core.windows.net\$($FileShareName)"  -Credential $credential

    if (Test-Path $LocalPath) {
        Remove-Item -Path $LocalPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $LocalPath | Out-Null
    Copy-Item -Path 'F:\*' -Destination $LocalPath -Recurse -Force
}
finally {
    Remove-PSDrive -Name F -Force -ErrorAction Ignore
}