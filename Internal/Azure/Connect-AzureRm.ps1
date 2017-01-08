function Connect-AzureRm {
    $azureProfilePath =  Join-Path $TempPath 'AzureRmProfile.json'
    try {
        $existingContext = Get-AzureRmContext
        if ($existingContext -and $existingContext.Account.AccountType -eq 'User') {
            Write-Host -NoNewline 'Saving current AzureRm context... '
            Save-AzureRmProfile -Path $azureProfilePath
            Write-Host 'Done'
            $existingContext | Format-List | Out-Host
            $existingContext | % Account | Format-List | Out-Host
            return
        }
     } catch {}

    $AzureUsername = Read-Host -Prompt "Azure Username"
    $securePassword = Read-Host -Prompt "$AzureUsername password" -AsSecureString

    try {
        $credential = New-Object PSCredential($AzureUsername, $securePassword)
        Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline "Logging into Azure.. "
        $rmContext = Add-AzureRmAccount -Credential $credential -ErrorAction Stop
        Write-Host -ForegroundColor Green -BackgroundColor Black "Successful"
        Write-Host -NoNewline 'Saving current AzureRm context... '
        Save-AzureRmProfile -Path $azureProfilePath
        Write-Host 'Done'
        $rmContext | Format-List | Out-Host
        $rmContext | % Account | Format-List | Out-Host
    }
    catch {
        Write-Host -ForegroundColor Red -BackgroundColor Black "Failed ($($_.Exception.Message))"
        throw
    }
}