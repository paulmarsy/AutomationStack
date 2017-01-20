Script JDKDownloader
{
    SetScript = {
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $cookie = New-Object System.Net.Cookie 
        $cookie.Name = "oraclelicense"
        $cookie.Value = "accept-securebackup-cookie"
        $cookie.Domain = ".oracle.com"
        $session.Cookies.Add($cookie);
        $uri = 'http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-windows-i586.exe'
        Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $session -OutFile 'D:\JDKInstall.exe'
    }
    TestScript = {
        (Test-Path 'D:\JDKInstall.exe')
    }
    GetScript = { @{} }
}
$javaInstallPath = 'C:\jdk8'
$id = "180112"
Package Java
{
    Ensure = 'Present'
    Name = "Java SE Development Kit 8 Update 112"
    Path = "D:\JDKInstall.exe"
    Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 INSTALLDIR=`"$javaInstallPath`" /l*v `"D:\JDKInstall.log`""
    ProductID = "32A3A4F4-B792-11D6-A78A-00B0D0${id}"
    DependsOn = "[Script]JDKDownloader"
}
Environment JavaHome
{
    Ensure = "Present" 
    Name = "JAVA_HOME"
    Value = $javaInstallPath
}