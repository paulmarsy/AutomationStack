xRemoteFile VSCodeDownloader
{
    Uri = 'https://az764295.vo.msecnd.net/stable/ee428b0eead68bf0fb99ab5fdc4439be227b6281/VSCodeSetup-1.8.1.exe'
    DestinationPath = 'D:\VSCodeSetup.exe'
    MatchSource = $false
}
xPackage VisualStudioCode
{
    Ensure = 'Present'
    Name = 'Microsoft Visual Studio Code'
    Path  = 'D:\VSCodeSetup.exe'
    ProductId = ''
    Arguments = "/verysilent /suppressmsgboxes /mergetasks=!runCode,desktopicon,addcontextmenufiles,addcontextmenufolders /log=`"D:\VSCodeSetup.log`""
    ReturnCode =  @(0, 3010, 1641)
    DependsOn = "[xRemoteFile]VSCodeDownloader"
}
