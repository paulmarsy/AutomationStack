function Register-NuGetAssembly {
    param($PackageId, $Version, $Framework, $Assembly)
    $tempFolder = Join-Path $script:TempPath 'Octosprache'
    $assemblyPath = Join-Path $tempFolder "lib\$Framework\$Assembly.dll"
    if (!(Test-Path $assemblyPath)) {
        Write-Host "Downloading $PackageId ($Version)"
        $tempFile = Join-Path $tempFolder ('{0}.{1}.zip' -f $PackageId, $Version)
        
        (New-Object System.Net.WebClient).DownloadFile("https://www.nuget.org/api/v2/package/$PackageId/$Version", $tempFile)
    
        $archive = [System.IO.Compression.ZipFile]::OpenRead($tempFile)
        try {
            $archive.Entries | % {
                $dest = Join-Path $tempFolder $_.FullName
                $parentDest = Split-Path $dest
                if (!(Test-Path $parentDest)) { 
                    New-Item -Path $parentDest -ItemType Directory | Out-Null
                }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $dest, $true)
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    Write-Host "Loading $Assembly..."
    Add-Type -Path $assemblyPath
}

$tempFolder = Join-Path $script:TempPath 'Octosprache'
if (!(Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
}
Add-Type -Assembly System.IO.Compression.FileSystem
Register-NuGetAssembly 'Newtonsoft.Json' '9.0.1' 'net40'          'Newtonsoft.Json'
Register-NuGetAssembly 'Sprache'         '2.1.0' 'net40'          'Sprache'        
Register-NuGetAssembly 'Octostache'      '2.0.7' 'net40'          'Octostache'     
Register-NuGetAssembly 'Humanizer.Core'  '2.1.0' 'netstandard1.0' 'Humanizer'    
