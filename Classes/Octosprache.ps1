function Register-NuGetAssembly {
    param($PackageId, $Version, $Framework, $Assembly)
    $tempFolder = Join-Path $script:TempPath 'Octosprache'
    $assemblyPath = Join-Path $tempFolder "lib\$Framework\$Assembly.dll"
    if (!(Test-Path $assemblyPath)) {
        Write-Verbose "Downloading $PackageId ($Version)"
        $download = Invoke-WebRequest -UseBasicParsing -Uri "https://www.nuget.org/api/v2/package/$PackageId/$Version"
    
        $tempFile = Join-Path $tempFolder ('{0}.{1}.zip' -f $PackageId, $Version)
        Set-Content -Path $tempFile -Value $download.Content -Force -Encoding Byte
        
        Expand-Archive -Path $tempFile -DestinationPath $tempFolder -Force
    }
    Write-Verbose "Loading $Assembly..."
    Add-Type -Path $assemblyPath
}

$tempFolder = Join-Path $script:TempPath 'Octosprache'
if (!(Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
}
Register-NuGetAssembly 'Newtonsoft.Json' '9.0.1' 'net40'          'Newtonsoft.Json'
Register-NuGetAssembly 'Sprache'         '2.1.0' 'net40'          'Sprache'
Register-NuGetAssembly 'Octostache'      '2.0.7' 'net40'          'Octostache'
Register-NuGetAssembly 'Humanizer.Core'  '2.1.0' 'netstandard1.0' 'Humanizer'
