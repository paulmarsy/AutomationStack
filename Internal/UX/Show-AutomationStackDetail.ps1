function Show-AutomationStackDetail {
    Write-Host
    Write-Host -ForegroundColor White (@(
        ("`t ")
        ([string][char]0x2554)
        (([string][char]0x2550)*40)
        ([string][char]0x2557)) -join '')
    Write-Host -ForegroundColor White "`t" "$(([string][char]0x2551)) AutomationStack Deployment Details".PadRight(40)([string][char]0x2551)
    Write-Host -ForegroundColor White (@(
        ("`t ")
        ([string][char]0x2560)
        (([string][char]0x2550)*40)
        ([string][char]0x2563)) -join '')
    Write-Host -ForegroundColor White "`t" "$(([string][char]0x2551)) Unique Deployment Prefix: $($CurrentContext.Get('UDP'))".PadRight(40)([string][char]0x2551)
    Write-Host -ForegroundColor White "`t" "$(([string][char]0x2551)) Admin Username: $($CurrentContext.Get('StackAdminUsername'))".PadRight(40)([string][char]0x2551)  
    Write-Host -ForegroundColor White "`t" "$(([string][char]0x2551)) Admin Password: $($CurrentContext.Get('StackAdminPassword'))".PadRight(40)([string][char]0x2551)  
    Write-Host -ForegroundColor White (@(
        ("`t ")
        ([string][char]0x255A)
        (([string][char]0x2550)*40)
        ([string][char]0x255D)) -join '')
    Write-Host
}