function New-KeyVaultSecret {
    param($Name, $Value)

    Write-Host -NoNewLine ("New Azure KeyVault secret ${Name}: {0}... " -f ('*'*$Value.Length))
    $secureValue = ConvertTo-SecureString -String $Value -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName $CurrentContext.Get('KeyVaultName') -Name $Name -SecretValue $secureValue | Out-Null
    Write-Host 'securely created'
}