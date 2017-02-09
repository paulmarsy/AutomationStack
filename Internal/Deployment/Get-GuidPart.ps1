function Get-GuidPart {
    param(
        [Parameter(Position=1,Mandatory)][ValidateSet('4','8','12')]$Length,
        [switdh]$ToUpper
    )
    $guid = [guid]::NewGuid().guid
    # X & Y - Not random
    # 22222222-1111-X444-Y444-333333333333
    $part = switch ($Length) {
        '4' { $guid.Substring(9,4) }
        '8' { $guid.Substring(0,8) }
        '12' { $guid.Substring(24,12) }
    }
    if ($ToUpper) { $part.ToUpperInvariant() }
    else { $part }
}