filter Repair-Json { 
    return ([regex]::replace(($_ -replace '\{\s*\}', '{}'),'\\u[a-fA-F0-9]{4}',{[char]::ConvertFromUtf32(($args[0].Value -replace '\\u','0x'))}))
}