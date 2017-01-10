$nsg = Get-AzureRmNetworkSecurityGroup -Name $TeamCityNSGName -ResourceGroupName $InfraRg

$rdpRule = $nsg | % SecurityRules | ? { $_.Name -eq 'RDP' -and $_.Priority -eq 999 }
$rdpRule.Access = 'Allow'

$nsg | Set-AzureRmNetworkSecurityGroup
