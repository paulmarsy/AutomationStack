function Select-ComputeVmAutoShutdown {
    $result = $Host.UI.PromptForChoice("Azure VM Auto-Shutdown", "Automatically shutdown Azure Virtual Machines after", ([System.Management.Automation.Host.ChoiceDescription[]]@(
        (New-Object System.Management.Automation.Host.ChoiceDescription '&None'),
        (New-Object System.Management.Automation.Host.ChoiceDescription 'Thr&ee Hours'),
        (New-Object System.Management.Automation.Host.ChoiceDescription 'Six Hou&rs'),
        (New-Object System.Management.Automation.Host.ChoiceDescription '&Twelve Hours'),
        (New-Object System.Management.Automation.Host.ChoiceDescription 'Twent&y-Four Hours'))), 2)

    $duration = switch ($result) {
        0 { 0 }
        1 { 3 }
        2 { 6 }
        3 { 12 }
        4 { 24 }
    }

    @{
        Status = (if ($result -eq 0) {'Disabled'} else {'Enabled'})
        Time = (Get-Date | % AddHours $duration | % ToString 'HH00')
    }
}