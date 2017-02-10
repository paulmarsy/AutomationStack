if ($FoldersToExclude -eq 'none') { return }

Get-ChildItem -Path $ExportPath -Directory | ? Name -in ($FoldersToExclude -split "`n") |
    Remove-Item -Force -Recurse