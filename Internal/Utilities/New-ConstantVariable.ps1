function New-ConstantVariable {
    param(
        [Parameter(Position=1,Mandatory)][ValidateNotNullOrEmpty()][string]$Name,
        [Parameter(Position=2,Mandatory,ValueFromRemainingArguments)][ValidateNotNull()][object]$Value
    )
    if ($Value -is [string] -and $Value.TrimStart()[0] -eq '=') {
        $Value = $Value.TrimStart().Substring(1, $Value.TrimStart().Length-1)
    }
    if ($Value -is  [System.Collections.IEnumerable] -and $Value[0] -is [string] -and $Value[0].Trim() -eq '=') {
        $Value = $Value[1]
    }

    New-Variable -Name $Name -Value $Value -Scope 1 -Option Constant
}
Set-Alias -Name const -Value New-ConstantVariable