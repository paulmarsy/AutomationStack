function Invoke-DSCComposition {
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

    Format-DSCFile -FilePath $Path | Out-String | % Trim
}