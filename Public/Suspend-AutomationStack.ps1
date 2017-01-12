function Suspend-AutomationStack {
    Stop-AzureRmVM -ResourceGroupName $CurrentContext.Get('OctopusRg') -Name $CurrentContext.Get('OctopusVMName')

Start-AzureStorageBlobCopy -Context $contextSource -SrcContainer source -SrcBlob test1 -DestContext $contextDestination -DestContainer backup

}