Stop-Service OctopusDeploy -Force

& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey}

& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{Password} --overwrite
& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" admin --username=#{Username} --password=#{Password}

& net use O: /DELETE

Start-Service OctopusDeploy
Start-Sleep -Seconds 30

Install-Package OctopusTools -Source https://www.nuget.org/api/v2 -Force -Destination $env:TEMP -RequiredVersion '4.5.0'
$octo = Join-Path $Env:TEMP 'OctopusTools.4.5.0\tools\Octo.exe' -Resolve
$defaultArgs = @(
    '--server="#{OctopusHostHeader}"'
    '--debug'
    '--apikey=#{ApiKey}'
)

$teamcityVer = '10.0.4'
& $octo create-release @defaultArgs --project="Provision TeamCity" --packageversion=$teamcityVer --releaseNumber=$teamcityVer
& $octo create-release @defaultArgs --project="Export Octopus Server Data" --releaseNumber="1.0.0"

