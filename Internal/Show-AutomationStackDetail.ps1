function Show-AutomationStackDetail {
    param(
          [Parameter(ParameterSetName='ByGuid',Mandatory=$true)][string]$Guid,
          [Parameter(ParameterSetName='ByGuid',Mandatory=$true)][string]$AzureRegion,
          [Parameter(ParameterSetName='ByOctosprache',Mandatory=$true)][Octosprache]$Octosprache
    )
    if ($Guid) {
        $UDP = $Guid.Substring(9,4)
        $context = @{
            UDP = $UDP
            Username = 'Stack'
            Password = ($Guid.Substring(0,8) + (($Guid.Substring(24,10).GetEnumerator() | ? { [char]::IsLetter($_) } | % { [char]::ToUpper($_) }) -join ''))
            AzureRegion = $AzureRegion
        }
    }
    if ($Octosprache) {
        $context = @{
            UDP = $Octosprache.Get('UDP')
            Username = $Octosprache.Get('Username')
            Password = $Octosprache.Get('Password')
            AzureRegion = $Octosprache.Get('AzureRegion')
        }
    }
    Write-Host ('*'*40)
    Write-Host "AutomationStack Deployment Details" 
    Write-Host "Azure Region:" $context.AzureRegion
    Write-Host "Unique Deployment Prefix:" $context.UDP 
    Write-Host "Admin Username:" $context.Username  
    Write-Host "Admin Password:" $context.Password  
    Write-Host ('*'*40)

    $context
}