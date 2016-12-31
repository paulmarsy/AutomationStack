function Get-OctopusEncryptedValue {
    param($Password, $Value)

    $masterKey = New-Object System.Security.Cryptography.Rfc2898DeriveBytes @($password, [System.Text.Encoding]::UTF8.GetBytes("Octopuss"), 1000) | % GetBytes 16
    $plainText = [System.Text.Encoding]::UTF8.GetBytes($Value)

    $csp = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $csp.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $csp.KeySize = 128
    $csp.BlockSize = 128
    $csp.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $csp.Key = $masterKey
    $iv = $csp.IV
    $encryptor = $csp.CreateEncryptor()
    $ms = New-Object System.IO.MemoryStream
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream  @($ms, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $cryptoStream.Write($plainText, 0, $plainText.Length)
    $cryptoStream.FlushFinalBlock()
    return ([System.Convert]::ToBase64String($ms.ToArray()) + '|' + [System.Convert]::ToBase64String($iv))
}