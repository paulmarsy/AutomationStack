function Invoke-SharedScript {
    param(
        [Parameter(Position=1, Mandatory)][ValidateSet('Automation','AzureSQL','Resources')][string]$Category,
        [Parameter(Position=2, Mandatory)][ValidateScript({Test-Path ([System.IO.Path]::Combine($ScriptsPath, $Category, ('{0}.ps1' -f $_)))})][string]$ScriptName
    )
    DynamicParam {
        $ScriptFile = ([System.IO.Path]::Combine($ScriptsPath, $Category, ('{0}.ps1' -f $ScriptName))) 

        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        [scriptblock]::Create((Get-Content -Path $ScriptFile -Raw)).Ast.ParamBlock.Parameters  | % {
             New-DynamicParam -Name $_.Name.VariablePath.UserPath -DPDictionary $Dictionary
        }
        
        $Dictionary
    }
    process {
       $PSBoundParameters.Remove('Category') | Out-Null
       $PSBoundParameters.Remove('Script') | Out-Null
       if ($DebugMode) {
           $PSBoundParameters | Format-List | Out-Host
       }

        & $ScriptFile @PSBoundParameters
    }
}