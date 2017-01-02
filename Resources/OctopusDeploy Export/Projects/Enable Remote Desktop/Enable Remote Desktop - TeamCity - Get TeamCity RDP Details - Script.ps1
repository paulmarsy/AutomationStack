$ip = (Get-AzureRmPublicIpAddress -Name TeamCityPublicIP -ResourceGroupName $TeamCityRg).IpAddress
Write-Warning "IP: $ip"
Write-Warning "Password: $StackAdminPassword"
Write-Warning "Username: $StackAdminUsername"