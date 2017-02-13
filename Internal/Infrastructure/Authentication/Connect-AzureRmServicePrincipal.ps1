function Connect-AzureRmServicePrincipal {
    Write-Host
    Write-Host -ForegroundColor Green 'Changing Azure Authentiction Context from User Account to Service Principal'
    Write-Host
    try {
        $existingContext = Get-AzureRmContext
        if ($existingContext -and $existingContext.Account.AccountType -eq 'User') {
            Write-Host -NoNewline 'Saving current AzureRm context... '
            $azureProfilePath =  Join-Path $TempPath 'AzureRmProfile.json'
            Save-AzureRmProfile -Path $azureProfilePath -Force
            Write-Host 'done'
        }
    } catch {}
    
    $securePassword = ConvertTo-SecureString $CurrentContext.Get('ServicePrincipalClientSecret') -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($CurrentContext.Get('ServicePrincipalClientId'), $securePassword)
    try {
        Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline "Authenticating as AutomationStack Service Principal.. "
        $rmContext = Add-AzureRmAccount -Credential $credential -SubscriptionId $CurrentContext.Get('AzureSubscriptionId') -TenantId $CurrentContext.Get('AzureTenantId') -ServicePrincipal
        Write-Host -ForegroundColor Green -BackgroundColor Black "Successful"
        $rmContext | Format-List | Out-String | % Trim |  Out-Host
        $rmContext | % Account | Format-List | Out-String | % Trim |  Out-Host
    }
    catch [Microsoft.IdentityModel.Clients.ActiveDirectory.AdalServiceException] {
        if ($_.Exception.ServiceErrorCodes -eq '70001') {
            Write-Warning 'Service Principal creation still propogating...'
            Start-Sleep -Seconds 1
            Connect-AzureRmServicePrincipal
            return
        }
        throw
    }
}