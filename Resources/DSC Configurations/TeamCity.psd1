@{
    AllNodes = @(
        @{
            NodeName = 'Server'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Server (Windows)'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Server'
            }
        }
        @{
            NodeName = 'CloudAgent'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Agent Image'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Server'
            }       
        }
    )
}