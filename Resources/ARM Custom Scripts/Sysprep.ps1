param($LogFileName, $StorageAccountName, $StorageAccountKey)
. (Join-Path -Resolve $PSScriptRoot 'CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

if (!(Test-Path "$($env:SystemDrive)\sysprep")) { New-Item -ItemType Directory -Path "$($env:SystemDrive)\sysprep" | Out-Null }

if (Test-Path "$($env:SystemDrive)\sysprep\statefile") {
    'Sysprep already run' | Write-Log
    return
}

"{0}[ Running Sysprep ]{0}" -f ("-"*40) | Write-Log
$sysprepScriptblock = {
    do {
        Start-Sleep -Seconds 1
        $status = Get-ChildItem C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status\ -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content | ConvertFrom-Json
    } while ($status[0].status.code -ne 0)
    
    Start-Sleep -Seconds 60
    
    & (Join-Path -Resolve ([System.Environment]::SystemDirectory) 'sysprep\sysprep.exe') /oobe /generalize /quiet /shutdown
    [System.IO.FIle]::WriteAllText("$($env:SystemDrive)\sysprep\statefile", $LASTEXITCODE, [System.Text.Encoding]::ASCII)
}
$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($sysprepScriptblock.ToString()))

Start-Process -FilePath 'powershell.exe' -RedirectStandardOutput 'C:\sysprep\stdout' -RedirectStandardError 'C:\sysprep\stderr' -WorkingDirectory (Join-Path ([System.Environment]::SystemDirectory) 'sysprep') -ArgumentList @('-NonInteractive','-NoProfile',"-EncodedCommand $encodedCommand") -PassThru | Format-List -Force * | Out-String | Write-Log