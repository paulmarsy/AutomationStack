function Get-TeamCityHashedValue {
    param($Value)

    $saltBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($saltBytes)
    $salt = ([System.Convert]::ToBase64String($saltBytes).GetEnumerator() | ? { [char]::IsLetterOrDigit($_) } | Select-Object -First 16) -join ''
    if ($salt.Length -ne 16) { return Get-TeamCityHashedValue -Value $Value }

    [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes($salt + $Value)
    $ms = New-Object System.IO.MemoryStream -ArgumentList @(,$plainText)
    $hash = Get-FileHash -InputStream $ms -Algorithm MD5 | % Hash | % ToLowerInvariant

    $salt + ':' + $hash
}