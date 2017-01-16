param($Path)

$includePath = Join-Path (Split-Path $Path) 'includes'

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
Format-DSCFile -FilePath $Path