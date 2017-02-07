function Invoke-OctopusStackApi {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromRemainingArguments=$true,ValueFromPipeline=$true)]$Uri,
        $Body = $null,
        [ValidateSet("GET", "POST", "PUT", "DELETE")]$Method = "GET"
    )
    process {
        if ([string]::IsNullOrWhiteSpace($Uri)) { $Uri = '/' }

        $apiIndex = $Uri.ToLowerInvariant().IndexOf('/api/')
        if ($apiIndex -ne -1) { $Uri = $Uri.Substring($apiIndex+4, $Uri.Length-$apiIndex-4) }
        $appIndex = $Uri.ToLowerInvariant().IndexOf('/app#/')
        if ($appIndex -ne -1) { $Uri = $Uri.Substring($appIndex+5, $Uri.Length-$appIndex-5) }    

        $Uri = $Uri.Trim('/')
        if ($Uri.StartsWith('api', [System.StringComparison]::OrdinalIgnoreCase)) { $Uri = $Uri.Remove(0, 3).Trim('/') }
        $normalizedUri = '{0}/api/{1}' -f $CurrentContext.Get('OctopusHostHeader'), $Uri

        Invoke-WebRequest -Uri $normalizedUri -Method $Method -Body ($Body | ConvertTo-Json) -Headers @{ "X-Octopus-ApiKey" = $CurrentContext.Get('ApiKey') } -UseBasicParsing -ErrorAction Stop |
                % Content |
                ConvertFrom-Json
    }
}