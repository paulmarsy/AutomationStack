$ip = (Get-AzureRmPublicIpAddress -Name OctopusPublicIP -ResourceGroupName $OctopusRg).IpAddress
Write-Warning "IP: $ip"
Write-Warning "Password: $StackAdminPassword"
Write-Warning "Username: $StackAdminUsername"