Set-AzureRmVMAccessExtension -Name 'ResetStackAdminPassword' -ResourceGroupName $OctopusRg -Location $AzureRegion -VMName $OctopusVMName -UserName $StackAdminUsername -Password $NewPassword
