class OctopusEncoder {
    OctopusEncoder([Octosprache]$Octosprache, [string]$Password) {
        $this.Octosprache = $Octosprache
        $this.MasterKey = New-Object System.Security.Cryptography.Rfc2898DeriveBytes @($Password, [System.Text.Encoding]::UTF8.GetBytes("Octopuss"), 1000) | % GetBytes 16
    }
    hidden $Octosprache
    hidden $MasterKey

    Encrypt([string]$Key, [string]$Value) {
        [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes($Value)

        $csp = New-Object System.Security.Cryptography.AesCryptoServiceProvider
        $csp.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $csp.KeySize = 128
        $csp.BlockSize = 128
        $csp.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $csp.Key = $this.MasterKey
        $iv = $csp.IV
        $encryptor = $csp.CreateEncryptor()
        $ms = New-Object System.IO.MemoryStream
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream  @($ms, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $cryptoStream.Write($plainText, 0, $plainText.Length)
        $cryptoStream.FlushFinalBlock()
        $this.Octosprache.Set(('Encoding[OctopusEncrypt].{0}' -f $Key), ([System.Convert]::ToBase64String($ms.ToArray()) + '|' + [System.Convert]::ToBase64String($iv)))
    }
    Hash([string]$Key, [string]$Value) {
        [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $salt = New-Object byte[] 16
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
        $hashedValue = New-Object System.Security.Cryptography.Rfc2898DeriveBytes @($plainText, $salt, 1000) | % GetBytes 24
        $this.Octosprache.Set(('Encoding[OctopusHash].{0}' -f $Key), ((1000).ToString('X') + '$' + [System.Convert]::ToBase64String($salt) + '$' + [System.Convert]::ToBase64String($hashedValue)))
    }
    ApiKeyID([string]$Key, [string]$ApiKey) {
        [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes("Octopus-ApiKey-${ApiKey}")
        $csp = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
        $this.Octosprache.Set(('Encoding[OctopusApiKeyId].{0}' -f $Key), ("apikeys-" + (([System.Convert]::ToBase64String($csp.ComputeHash($plainText)).GetEnumerator() | ? { [char]::IsLetterOrDigit($_) }) -join '')))
    }
}