param($LogFileName, $StorageAccountName, $StorageAccountKey)
. (Join-Path -Resolve $PSScriptRoot 'CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

$sysprepStateFile = "$($env:SystemDrive)\sysprep.statefile"
if (Test-Path $sysprepStateFile) {
    'Sysprep already run' | Write-Log
    return
}

"{0}[ Setting Sysprep Flag ]{0}" -f ("-"*38) | Write-Log
 [System.IO.FIle]::WriteAllText($sysprepStateFile, (Get-Date -Format u),[System.Text.Encoding]::ASCII)

"{0}[ Running Sysprep ]{0}" -f ("-"*40) | Write-Log
Set-Location (Join-Path ([System.Environment]::SystemDirectory) 'sysprep')
$sysprep = Join-Path -Resolve ([System.Environment]::SystemDirectory) 'sysprep\sysprep.exe'
Write-Verbose "Found $sysprep"

& $sysprep /oobe /generalize /quiet /shutdown *>&1 | Write-Log
if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE from Sysprep" }