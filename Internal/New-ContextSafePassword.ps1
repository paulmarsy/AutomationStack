function New-ContextSafePassword {
    # Password without symbols, for convienience 
    $password = ''
    do {
        # xxxxxxxx-4444-Xxxx-Yxxx-555555555555
        $guid = [guid]::NewGuid().guid
        
        $pattern = $guid[9] % 2
        $passwordArray = for ($i = 24; $i -lt $guid.Length; $i++) {
            if ($i % 2 -eq $pattern) { [char]::ToUpperInvariant($guid[$i]) }
            else { [char]::ToLowerInvariant($guid[$i]) }
        }
        $password = $passwordArray -join ''
        # Must contain upper case character, must contain lowercase character, must contain digit, must be at least 12 characters
   } while ($password -cnotmatch '^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{12,}$')

    return $password
}