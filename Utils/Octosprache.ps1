<#
$octosprache = [octosprache]::new()
$octosprache.Add('token', 'value')
$octosprache.Eval('some string with  #{token}s in it')
$octosprache.ParseFile('file.txt')
#>
. (Join-Path $PSScriptRoot 'Get-OctopusEncryptedValue.ps1' -Resolve)
class Octosprache {
    Octosprache([string]$UDP) {

        $this.RegisterNuGetAssembly('Newtonsoft.Json', '9.0.1', 'net40', 'Newtonsoft.Json')
        $this.RegisterNuGetAssembly('Sprache', '2.1.0', 'net40', 'Sprache')
        $this.RegisterNuGetAssembly('Octostache', '2.0.7', 'net40', 'Octostache')
        $backingFile = Join-Path $PWD.ProviderPath ('AutomationStack {0} Config.json' -f $UDP)
        if (Test-Path $backingFile) { Write-Host 'Repopulating configuration from file' }

        $this.VariableDictionary = New-Object Octostache.VariableDictionary $backingFile
        Write-Warning "AutomationStack Configuration is being stored in file '$backingFile' and may contain sensitive deployment details"
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
    hidden $Guid = [guid]::NewGuid().Guid
    hidden $VariableDictionary

    Set([string]$Key, [string]$Value) {
         $this.VariableDictionary.Set($Key, $Value)
         $this.VariableDictionary.Save()
    }   
    SetSensitive([string]$Password, [string]$Key, [string]$Value) {
         $sensitiveValue = Get-OctopusEncryptedValue -Password $Password -Value $Value
         $this.Set($Key, $sensitiveValue)
    }
    [string] Get([string]$Key) {
        return $this.VariableDictionary.Get($Key)
    }
    [string] Eval([string]$Expression) {
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