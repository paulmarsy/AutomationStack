$octopusServerExe = Join-Path $env:ProgramFiles 'Octopus Deploy\Octopus\Octopus.Server.exe'
& $octopusServerExe configure --console --guestloginenabled=True