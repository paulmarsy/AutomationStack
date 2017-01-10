function Invoke-SharedScript {
    param(
        [Parameter(Position=1, Mandatory)][ValidateSet('Automation','AzureResources')]$Category,
        [Parameter(Position=2, Mandatory)]$ScriptFile
    )
    DynamicParam {
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $MyInvocation.MyCommand.Parameters.Keys ? % { $_ -in $MyInvocation.BoundParameters.Keys }
        $Dictionary.Add
        

    }
    process {
        $scriptPath = [System.IO.Path]::Combine($ResourcesPath, $Category, $ScriptFile)
        if (!(Test-Path $scriptPath) { throw "Unable to find shared script: $scriptPath" }
    }
}