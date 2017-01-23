class TeamCityEncoder {
    TeamCityEncoder([Octosprache]$Octosprache) {
        $this.Octosprache = $Octosprache
    }
    hidden $Octosprache
    hidden static $Prefix = 'zxx'
  
    hidden static [byte[]] GetUnsignedKey() {
        [sbyte[]]$SignedKey = @(61, 22, 11, 57, 110, 89, -20, -1, 0, 99, 111, -120, 55, 4, -9, 10, 11, 45, 71, -89, 21, -99, 54, 51)
        [byte[]]$unsignedKey = New-Object byte[] $SignedKey.Length
        [System.Buffer]::BlockCopy($SignedKey, 0, $unsignedKey, 0, $SignedKey.Length)
        return $unsignedKey 
    }
    [string] Unscramble([string] $Scrambled) {
        if (-not $Scrambled.StartsWith([TeamCityEncoder]::Prefix) -or (($Scrambled.Length-[TeamCityEncoder]::Prefix.Length) % 2) -ne 0) {
            throw "$Scrambled is not a valid scrambled string"
        }
        $scrambledWithoutPrefix = $Scrambled.Substring([TeamCityEncoder]::Prefix.Length, $Scrambled.Length-[TeamCityEncoder]::Prefix.Length)
        $encodedBytes = for ($i = 0; $i -lt $scrambledWithoutPrefix.Length; $i += 2) {
            [System.Convert]::ToByte($scrambledWithoutPrefix.Substring($i, 2), 16)
        }

        $csp = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider
        $csp.Mode = [System.Security.Cryptography.CipherMode]::ECB
        $csp.Key = [TeamCityEncoder]::GetUnsignedKey()
        $decryptor = $csp.CreateDecryptor()

        $decodedBytes = $decryptor.TransformFinalBlock($encodedBytes, 0, $encodedBytes.Count)

        return [System.Text.Encoding]::UTF8.GetString($decodedBytes)
    }
    Scramble([string]$Key, [string] $Value) {
        [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes($Value)

        $csp = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider
        $csp.Mode = [System.Security.Cryptography.CipherMode]::ECB
        $csp.Key = [TeamCityEncoder]::GetUnsignedKey()

        $encryptor = $csp.CreateEncryptor()
        $ms = New-Object System.IO.MemoryStream
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream  @($ms, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $cryptoStream.Write($plainText, 0, $plainText.Length)
        $cryptoStream.FlushFinalBlock()

        $scrambled = ([TeamCityEncoder]::Prefix + (($ms.ToArray() | % { $_.ToString('X') }) -join '')).ToLowerInvariant()
        $this.Octosprache.Set(('Encoding[TeamCityScramble].{0}' -f $Key), $scrambled)
    }
    Hash([string]$Key, [string]$Value) {
        $saltBytes = New-Object byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($saltBytes)
        $salt = ([System.Convert]::ToBase64String($saltBytes).GetEnumerator() | ? { [char]::IsLetterOrDigit($_) } | Select-Object -First 16) -join ''
        if ($salt.Length -ne 16) { $this.Hash($Key, $Value) }

        [byte[]]$plainText = [System.Text.Encoding]::UTF8.GetBytes($salt + $Value)
        $ms = New-Object System.IO.MemoryStream -ArgumentList @(,$plainText)
        $hash = Get-FileHash -InputStream $ms -Algorithm MD5 | % Hash | % ToLowerInvariant

        $this.Octosprache.Set(('Encoding[TeamCityHash].{0}' -f $Key), ($salt + ':' + $hash))
    }
}