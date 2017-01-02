Get-AzureRmNetworkSecurityGroup -Name $TeamCityNSGName -ResourceGroupName $TeamCityRg |
Add-AzureRmNetworkSecurityRuleConfig -Name OctopusTentacle -Protocol TCP -Access Allow -SourcePortRange * -SourceAddressPrefix Internet -DestinationPortRange 10933 -DestinationAddressPrefix * -Priority 300 -Direction Inbound  |
Set-AzureRmNetworkSecurityGroup
