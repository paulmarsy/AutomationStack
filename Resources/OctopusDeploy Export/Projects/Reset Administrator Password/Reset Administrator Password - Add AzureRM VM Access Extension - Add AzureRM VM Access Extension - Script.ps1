Set-AzureRmVMAccessExtension -Name 'ResetStackAdminPassword' -ResourceGroupName $ResourceGroupName -Location $AzureRegion -VMName $OctopusVMName -UserName $AdminUsername -Password $NewPassword
