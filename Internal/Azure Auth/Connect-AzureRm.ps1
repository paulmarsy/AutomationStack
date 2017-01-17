function Connect-AzureRm {
    if ($null -ne $CurrentContext -and $CurrentContext.Get('ServicePrincipalCreated')) {
        Connect-AzureRmServicePrincipal
        return
    }
    try {
        $existingContext = Get-AzureRmContext
        $existingContext | Format-List | Out-String | % Trim |  Out-Host
        $existingContext | % Account | Format-List | Out-String | % Trim |  Out-Host
     } catch {
        $AzureUsername = Read-Host -Prompt "Azure Username" | % Trim
        $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString
        $credential = New-Object PSCredential($AzureUsername, $securePassword)

        try {
            Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline "Logging into Azure.. "
            $rmContext = Add-AzureRmAccount -Credential $credential -ErrorAction Stop
            Write-Host -ForegroundColor Green -BackgroundColor Black "Successful"
            $rmContext | Format-List | Out-String | % Trim |  Out-Host
            $rmContext | % Account | Format-List | Out-String | % Trim |  Out-Host
        }
        catch {
            Write-Host -ForegroundColor Red -BackgroundColor Black "Failed ($($_.Exception.Message))"
            throw
        }
     }

    Set-AzureSubscriptionSelection
}