class Octosprache {
    Octosprache([string]$UDP) {
        $backingFile = Join-Path $script:DeploymentsPath ('{0}.json' -f $UDP)
        if (Test-Path $backingFile) { Write-Host 'Repopulating Octosprache configuration from file' }
        else { Write-Host 'Creating new Octosprache configuration' }
        
        $this.VariableDictionary = New-Object Octostache.VariableDictionary $backingFile
        $this.ARMTemplateVariableDictionary = New-Object Octostache.VariableDictionary

        $this.Set('UDP', $UDP)
    }
    hidden static [string] PrepareJson([string]$Json) {
        $deserialized = ConvertFrom-Json -InputObject $Json
        $minifiedJson = ConvertTo-Json -InputObject $deserialized -Depth 100 -Compress | % { $_ -replace '\{\s*\}', '{}' } 
        $decodedJson = [regex]::replace($minifiedJson,'\\u[a-fA-F0-9]{4}',{[char]::ConvertFromUtf32(($args[0].Value -replace '\\u','0x'))})
        return $decodedJson
    }
    hidden $VariableDictionary
    hidden $ARMTemplateVariableDictionary

    Set([string]$Key, [string]$Value) {
         $this.VariableDictionary.Set($Key, $Value)
         $this.VariableDictionary.Save()
    }   
    SetARMTemplate([string]$Key, [string]$Template) {
        $this.ARMTemplateVariableDictionary.Set(('AzureResourceManager[{0}].Template' -f $Key), [Octosprache]::PrepareJson($Template))
    }  
    SetARMParameters([string]$Key, [string]$Parameters) {
        $this.ARMTemplateVariableDictionary.Set(('AzureResourceManager[{0}].Parameters' -f $Key), [Octosprache]::PrepareJson($Parameters))
    }
    [string] EvalARMTemplate([string]$Expression) {
        return $this.ARMTemplateVariableDictionary.Evaluate($Expression)
    }
    ParseARMTemplateFile($From, $To) {
        $content = Get-Content -Path $From -Raw
        $tokenised = $this.EvalARMTemplate($content)
        Set-Content -Path $To -Value $tokenised -Encoding ASCII
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
    TimingStart([string]$Key) {
        $this.Set(('Timing[{0}].Start' -f $Key), (Get-Date))
    }
    TimingEnd([string]$Key) {
        $this.Set(('Timing[{0}].End' -f $Key), (Get-Date))
    }
    [string] GetTiming([string]$Key) {
        $startdatetime = $this.Get(('Timing[{0}].Start' -f $Key))
        if (!$startdatetime) {
            return "Not started"
        }
        $enddatetime = $this.Get(('Timing[{0}].End' -f $Key))
        if (!$enddatetime) {
            return "Not completed"
        }
        $timespan = ([datetime]$enddatetime) - ([datetime]$startdatetime)
        return [Humanizer.TimeSpanHumanizeExtensions]::Humanize($timespan, 2)
    }
    [string] ToString()
    {
        return ('Octosprache[{0}]' -f $this.Get('UDP'))
    }
}