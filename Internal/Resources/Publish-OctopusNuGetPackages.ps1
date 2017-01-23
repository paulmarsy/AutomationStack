function Publish-OctopusNuGetPackages {
    Send-ToOctopusPackageFeed (Join-Path -Resolve $ResourcesPath 'ARM Templates') 'ARMTemplates'
    Get-ChildItem -Path $ScriptsPath -Directory | % {
        Send-ToOctopusPackageFeed ($_.FullName | Convert-Path) ('AutomationStackScripts.{0}' -f $_.BaseName)
    }
}