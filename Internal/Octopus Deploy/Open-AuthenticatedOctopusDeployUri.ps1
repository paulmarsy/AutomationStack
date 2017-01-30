function Open-AuthenticatedOctopusDeployUri {
    $apikey = Invoke-OctopusStackApi -Uri '/api/users/Users-2/apikeys' -Method POST -Body @{Purpose = 'Login Token'}
    Start-Process -FilePath "$($CurrentContext.Get('OctopusHostHeader'))/api/users/Users-2/authenticate/apikey/$($apikey.ApiKey)"
}