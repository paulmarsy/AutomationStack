function Get-OctopusApiKeyId {
    param($ApiKey)

    $key = [System.Text.Encoding]::UTF8.GetBytes("Octopus-ApiKey-${ApiKey}")
    $csp = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    "apikeys-" + (([System.Convert]::ToBase64String($csp.ComputeHash($key)).GetEnumerator() | ? { [char]::IsLetterOrDigit($_) }) -join '')
} 