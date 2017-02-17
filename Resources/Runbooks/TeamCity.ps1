
        teamcityDscJobId = [System.Guid]::NewGuid().ToString()
        teamcityDscConfiguration = $teamcityDscConfiguration
        teamcityDscConfigurationData = $teamcityDscConfigurationData
        teamcityDscTentacleRegistrationUri = $CurrentContext.Get('OctopusHostHeader')
        teamcityDscTentacleRegistrationApiKey = $CurrentContext.Get('ApiKey')
        teamcityDscHostHeader = $CurrentContext.Get('TeamCityHostHeader')
        teamcityCustomScriptLogFile = $CurrentContext.Get('TeamCityCustomScriptLogFile')