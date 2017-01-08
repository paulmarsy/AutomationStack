function Show-AutomationStackDetail {
    param(
          [Parameter(ParameterSetName='ByGuid',Mandatory=$true)][string]$Guid,
          [Parameter(ParameterSetName='ByGuid',Mandatory=$true)][string]$AzureRegion,
          [Parameter(ParameterSetName='ByOctosprache',Mandatory=$true)]$Octosprache
    )
    if ($Guid) {
        $UDP = $Guid.Substring(9,4)
        $context = @{
            UDP = $UDP
            Username = 'Stack'
            Password = ($Guid.Substring(0,8) + (($Guid.Substring(24,10).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join ''))
            AzureRegion = $AzureRegion
            AzureRegionValue = (Get-AzureLocations | ? Name -eq $AzureRegion | % Value)
        }
        if (!($context.Password.GetEnumerator() | ? { [char]::IsNumber($_) })) { throw "Password did not contain any numbers" }
        if (!($context.Password.GetEnumerator() | ? { [char]::IsLower($_) })) { throw "Password did not contain any lowercase characters" }
        if (!($context.Password.GetEnumerator() | ? { [char]::IsUpper($_) })) { throw "Password did not contain any uppercase characters" }
    }
    if ($Octosprache) {
        $context = @{
            UDP = $Octosprache.Get('UDP')
            Username = $Octosprache.Get('Username')
            Password = $Octosprache.Get('Password')
            AzureRegion = $Octosprache.Get('AzureRegion')
            AzureRegionValue = $Octosprache.Get('AzureRegionValue')
        }
    }
    Write-Host -ForegroundColor White -BackgroundColor Black (@(
        ([string][char]0x2554)
        (([string][char]0x2550)*40)
        ([string][char]0x2557)) -join '')
    Write-Host "$(([string][char]0x2551)) AutomationStack Deployment Details".PadRight(40)([string][char]0x2551)
        Write-Host -ForegroundColor White -BackgroundColor Black (@(
        ([string][char]0x2560)
        (([string][char]0x2550)*40)
        ([string][char]0x2563)) -join '')
    Write-Host "$(([string][char]0x2551)) Unique Deployment Prefix: $($context.UDP)".PadRight(40)([string][char]0x2551)
    Write-Host "$(([string][char]0x2551)) Admin Username: $($context.Username)".PadRight(40)([string][char]0x2551)  
    Write-Host "$(([string][char]0x2551)) Admin Password: $($context.Password)".PadRight(40)([string][char]0x2551)  
    Write-Host -ForegroundColor White -BackgroundColor Black (@(
        ([string][char]0x255A)
        (([string][char]0x2550)*40)
        ([string][char]0x255D)) -join '')

    $context
}