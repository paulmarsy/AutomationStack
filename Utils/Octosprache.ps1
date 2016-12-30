<#
$octosprache = [octosprache]::new()
$octosprache.Add('token', 'value')
$octosprache.Eval('some string with  #{token}s in it')
$octosprache.ParseFile('file.txt')
#>

class Octosprache {
    Octosprache() {

        $this.RegisterNuGetAssembly('Sprache', '2.1.0', 'net40', 'Sprache')
        $this.RegisterNuGetAssembly('Octostache', '2.0.7', 'net40', 'Octostache')

        $this.VariableDictionary = New-Object Octostache.VariableDictionary
    }
    RegisterNuGetAssembly($PackageId, $Version, $Framework, $Assembly) {
        $download = Invoke-WebRequest -Verbose -UseBasicParsing -Uri "https://www.nuget.org/api/v2/package/$PackageId/$Version"
        $tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'zip')
        Write-Host "Saving $PackageId $Version to ${tempFile}"
        Set-Content -Path $tempFile -Value $download.Content -Force -Encoding Byte
        $tempFolder = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $this.Guid)
        Expand-Archive -Path $tempFile -DestinationPath $tempFolder -Force
            
        Write-Host "Loading $Assembly..."
        Add-Type -Path (Join-Path -Resolve $tempFolder "lib\$Framework\$Assembly.dll")
    }
    $Guid = [guid]::NewGuid().Guid
    $VariableDictionary

    Add($Key, $Value) {
         $this.VariableDictionary.Set($Key, $Value)
    }
    [string] Eval($Expression) {
        return $this.VariableDictionary.Evaluate($Expression)
    }
    ParseFile($FilePath) {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $tokenised = $this.Eval($content)
        Set-Content -Path $FilePath -Value $tokenised -Encoding UTF8
    }
    ParseFile($From, $To) {
        $content = Get-Content -Path $From -Raw -Encoding UTF8
        $tokenised = $this.Eval($content)
        Set-Content -Path $To -Value $tokenised -Encoding UTF8
    }
}