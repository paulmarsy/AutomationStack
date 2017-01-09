$ip = (Get-AzureRmPublicIpAddress -Name TeamCityPublicIP -ResourceGroupName $TeamCityRg).IpAddress
"IP: $ip"