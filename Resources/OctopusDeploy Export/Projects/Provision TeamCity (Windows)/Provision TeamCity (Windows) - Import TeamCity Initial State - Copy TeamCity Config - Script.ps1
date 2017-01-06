$srcConfig = Join-Path $ExportPath 'config'
$dstConfig = Join-Path $TeamCityDataDir 'config'
if (Test-Path $dstConfig) {
    Remove-Item -Path $dstConfig -Recurse -Force 
}
Copy-Item -Recurse -Force -Path $srcConfig -Destination $TeamCityDataDir