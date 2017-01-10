$ip = (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName $OctopusRg).IpAddress
"IP: $ip"
"Password: $StackAdminPassword"
"Username: $StackAdminUsername"