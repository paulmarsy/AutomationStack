function Invoke-SharedScript {
    param(
        [Parameter(Position=1, Mandatory)][ValidateSet('Automation','AzureSQL','Resources')]$Category,
        [Parameter(Position=2, Mandatory)]$Script
    )
    DynamicParam {
        $scriptPath = [System.IO.Path]::Combine($ResourcesPath, $Category, ('{0}.ps1' -f $ScriptFile))
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        [scriptblock]::Create((Get-Content -Path $scriptPath -Raw)).Ast.ParamBlock.Parameters  | % {
             New-DynamicParam -Name $_.Name.VariablePath.UserPath -DPDictionary $Dictionary
        }
        
        $Dictionary
    }
    process {
        $scriptPath = [System.IO.Path]::Combine($ResourcesPath, $Category, ('{0}.ps1' -f $ScriptFile))
        if (!(Test-Path $scriptPath)) { throw "Unable to find shared script: $scriptPath" }

        $PSBoundParameters | out-host

        & $scriptPath
    }
}