function Connect-AzureRm {
    param(
        $AzureUsername,
        $AzurePassword
    )

    if (!($AzureUsername)) { $AzureUsername = Read-Host -Prompt "Azure Username" } 
    if (!($AzurePassword)) { $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString }
    else { $securePassword = $AzurePassword | ConvertTo-SecureString -AsPlainText -Force }

    try {
        $credential = New-Object PSCredential($AzureUsername, $securePassword)
        Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline "Logging into Azure.. "
        $rmContext = Add-AzureRmAccount -Credential $credential -ErrorAction Stop
        Write-Host -ForegroundColor Green -BackgroundColor Black "Successful"
        $rmContext | Format-List | Out-Host
        $rmContext | % Account | Format-List | Out-Host
    }
    catch {
        Write-Host -ForegroundColor Red -BackgroundColor Black "Failed ($($_.Exception.Message))"
        throw
    }
}