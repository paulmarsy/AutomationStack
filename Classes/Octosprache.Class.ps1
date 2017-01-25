class Octosprache {
    Octosprache() {
        $this.VariableDictionary = New-Object Octostache.VariableDictionary
    }
    Octosprache([string]$UDP) {
        $backingFile = Join-Path $script:DeploymentsPath ('{0}.config.json' -f $UDP)        
        $this.VariableDictionary = New-Object Octostache.VariableDictionary $backingFile
    }

    hidden $VariableDictionary

    Set([string]$Key, [string]$Value) {
         $this.VariableDictionary.Set($Key, $Value)
         $this.VariableDictionary.Save()
    }   
    [string] Get([string]$Key) {
        return $this.VariableDictionary.Get($Key)
    }
    [string] GetRaw([string]$Key) {
        return $this.VariableDictionary.GetRaw($Key)
    }
    [string] Eval([string]$Expression) {
        return $this.VariableDictionary.Evaluate($Expression)
    }
    ParseFile($From, $To) {
        $content = Get-Content -LiteralPath $From -Raw
        $tokenised = $this.Eval($content)
        Set-Content -LiteralPath $To -Value $tokenised -Encoding ASCII
    }
    [Octosprache] Clone() {
        $clone = New-Object Octosprache
        $this.VariableDictionary.GetNames() | % {
            $clone.Set($_, $this.GetRaw($_))
        }
        return $clone
    }
    [string] ToString() {
        return ('Octosprache[{0}]' -f $this.Get('UDP'))
    }
}