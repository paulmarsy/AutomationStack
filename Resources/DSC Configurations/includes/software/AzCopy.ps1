xRemoteFile AzCopyDownloader
{
    Uri = 'http://aka.ms/downloadazcopy'
    DestinationPath = 'D:\azcopy.msi'
    MatchSource = $false
}
xPackage AzCopy
{
    Ensure = 'Present'
    Name = 'Microsoft Azure Storage Tools - v5.2.0'
    Path  = 'D:\azcopy.msi'
    ProductId = '89B7B8B5-CC31-4C78-8E83-1E5B9506C322'
    Arguments = "/quiet"
    DependsOn = "[xRemoteFile]AzCopyDownloader"
}
