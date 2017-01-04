function Get-OctospracheState {
    param(
        $UDP
    )
    if ($UDP) { [octosprache]::new($UDP) }
    else { $CurrentContext }
}