xRemoteFile AzCopyDownloader
{
    Uri = 'http://aka.ms/downloadazcopy'
    DestinationPath = 'D:\azcopy.msi'
    MatchSource = $false
}
xPackage AzCopy
{
    Ensure = 'Present'
    Name = 'azcopy'
    Path  = 'D:\azcopy.msi'
    ProductId = ''
    Arguments = "/quiet"
    DependsOn = "[xRemoteFile]AzCopyDownloader"
}
