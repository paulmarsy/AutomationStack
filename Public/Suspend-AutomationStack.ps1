function Suspend-AutomationStack {
    Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName
Start-AzureStorageBlobCopy -Context $contextSource -SrcContainer source -SrcBlob test1 -DestContext $contextDestination -DestContainer backup

}