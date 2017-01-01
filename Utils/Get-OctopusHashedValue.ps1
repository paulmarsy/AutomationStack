function Get-OctopusHashedValue {
    param($Value)

    $plainText = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $salt = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
    $hashedValue = New-Object System.Security.Cryptography.Rfc2898DeriveBytes @($plainText, $salt, 1000) | % GetBytes 24
    (1000).ToString('X') + '$' + [System.Convert]::ToBase64String($salt) + '$' + [System.Convert]::ToBase64String($hashedValue)
}