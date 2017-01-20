param($Path)

$Path = Get-Item -Path $Path | % FullName
$includePath = Join-Path (Split-Path $Path) 'includes'
if (!(Test-Path $includePath)) {
    throw "Unable to find include location for DSC composition: $includePath"
}

function Format-DSCFile {
    param($FilePath)
    Get-Content -Path $FilePath | % {
        if ($_ -match '^\s*\#include\s+<(?<file>[^<>]+)>\s*$') {
            $includeFile = Join-Path $includePath ('{0}.ps1' -f $Matches['file'].Trim())
            Format-DSCFile -FilePath $includeFile
        }
        else { $_ }
    }
}

$resolvedConfiguration = Format-DSCFile -FilePath $Path

$tempFile = Join-Path $env:TEMP (Split-Path $Path -Leaf)
if (Test-Path $tempFile) {
    Remove-Item $tempFile -Force
}
Set-Content -Path $tempFile -Value $resolvedConfiguration
Write-Host  "Complete DSC Configuration: $tempFile"

return $tempFile
