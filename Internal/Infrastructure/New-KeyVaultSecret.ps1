function New-KeyVaultSecret {
    param($Name, $Value)

    Write-Host -NoNewLine ("Azure KeyVault Secret ${Name}: {0}... " -f ('*'*[System.Math]::Min($Host.UI.RawUI.BufferSize.Width-75, $Value.Length)))
    $secureValue = ConvertTo-SecureString -String $Value -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName $CurrentContext.Eval('keyvault-#{UDP}') -Name $Name -SecretValue $secureValue -Tag @{ application = 'AutomationStack'; udp = $CurrentContext.Get('UDP') } | Out-Null
    Write-Host 'securely created'
}