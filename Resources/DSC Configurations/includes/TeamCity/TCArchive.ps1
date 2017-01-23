xRemoteFile TeamCityDownload
{
    Uri = "https://download.jetbrains.com/teamcity/TeamCity-$($TeamCityVersion).tar.gz"
    DestinationPath = "D:\TeamCity-$($TeamCityVersion).tar.gz"
    MatchSource = $false
}
Script TeamCityExtract
{
    SetScript = {
        & "${env:ProgramFiles}\7-Zip\7z.exe" e "D:\TeamCity-$($using:TeamCityVersion).tar.gz" -o"D:\"
        & "${env:ProgramFiles}\7-Zip\7z.exe" x "D:\TeamCity-$($using:TeamCityVersion).tar" -o"D:\"  
    }
    TestScript = {
        (Test-Path "D:\TeamCity")
    }
    GetScript = { @{} }
    DependsOn = @('[xRemoteFile]TeamCityDownload','[Package]SevenZip')
}
