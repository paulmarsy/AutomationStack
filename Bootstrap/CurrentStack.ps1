param($Guid)

$UDP = $Guid.Substring(9,4)
$context = @{
    UDP = $UDP
    Username = 'Stack'
    Password = ($Guid.Substring(0,8) + (($Guid.Substring(24,10).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join ''))
}
Write-Host ('*'*40)
Write-Host "AutomationStack Deployment Details" 
Write-Host "Unique Deployment Prefix: " $context.UDP 
Write-Host "Admin Username: " $context.Username  
Write-Host "Admin Password: " $context.Password  
Write-Host ('*'*40)

return $context