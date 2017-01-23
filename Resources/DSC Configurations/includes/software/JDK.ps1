Script JDKDownloader
{
    SetScript = {
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $cookie = New-Object System.Net.Cookie 
        $cookie.Name = "oraclelicense"
        $cookie.Value = "accept-securebackup-cookie"
        $cookie.Domain = ".oracle.com"
        $session.Cookies.Add($cookie);
        $uri = 'http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-windows-i586.exe'
        Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $session -OutFile 'D:\JDKInstall.exe'
    }
    TestScript = {
        $hash = 'B57ABCFBCDD42D15626775FB214811328F614A9A9E623D4904BBFD6BB2AAC79F'
        ((Test-Path 'D:\JDKInstall.exe') -and (Get-FileHash -Path 'D:\JDKInstall.exe' -Algorithm SHA1 | % Hash) -eq $hash)
    }
    GetScript = { @{} }
}
$javaInstallPath = 'C:\jdk8'
$id = "180121"
xPackage Java
{
    Ensure = 'Present'
    Name = "Java SE Development Kit 8 Update 121"
    Path = "D:\JDKInstall.exe"
    ProductID = "32A3A4F4-B792-11D6-A78A-00B0D0${id}"
    Arguments = "/s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" INSTALLDIR=$javaInstallPath INSTALL_SILENT=Enable REBOOT=Disable /L D:\JDKInstall.log"
    ReturnCode =  @(0)
    DependsOn = "[Script]JDKDownloader"
}

Environment JavaHome
{
    Ensure = "Present" 
    Name = "JAVA_HOME"
    Value = $javaInstallPath
    DependsOn = "[xPackage]Java"
}