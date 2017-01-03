<#
. '..\Utils\Octosprache.ps1'
$context = [octosprache]::new('')

. 'AutomationStack\Utils\Octosprache.ps1'
$context = [octosprache]::new('')
#>
. (Join-Path $PSScriptRoot 'Import Helpers\Get-OctopusEncryptedValue.ps1' -Resolve)
. (Join-Path $PSScriptRoot 'Import Helpers\Get-OctopusHashedValue.ps1' -Resolve)
. (Join-Path $PSScriptRoot 'Import Helpers\Get-OctopusApiKeyId.ps1' -Resolve)
. (Join-Path $PSScriptRoot 'Import Helpers\Get-TeamCityHashedValue.ps1' -Resolve)
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
    SetOctopusHashed([string]$Key, [string]$Value) {
         $hashedValue = Get-OctopusHashedValue -Value $Value
         $this.Set($Key, $hashedValue)
    }   
    SetTeamCityHashed([string]$Key, [string]$Value) {
         $hashedValue = Get-TeamCityHashedValue -Value $Value
         $this.Set($Key, $hashedValue)
    }   
    SetApiKeyId([string]$Key, [string]$ApiKey) {
         $apiKeyId = Get-OctopusApiKeyId -ApiKey $ApiKey
         $this.Set($Key, $apiKeyId)
    }
    [string] Get([string]$Key) {
        return $this.VariableDictionary.Get($Key)
    }
    [string] Eval([string]$Expression) {
        return $this.VariableDictionary.Evaluate($Expression)
    }
    ParseFile($FilePath) {
        $content = Get-Content -Path $FilePath -Raw
        $tokenised = $this.Eval($content)
        Set-Content -Path $FilePath -Value $tokenised -Encoding ASCII
    }
    ParseFile($From, $To) {
        $content = Get-Content -Path $From -Raw
        $tokenised = $this.Eval($content)
        Set-Content -Path $To -Value $tokenised -Encoding ASCII
    }
}