Set-Location (Join-Path $env:windir 'system32\sysprep')
& sysprep.exe /oobe /generalize /quiet /shutdown