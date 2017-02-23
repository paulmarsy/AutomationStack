function Upload-AzureTemporaryFile {
    param($Path)

    $authorizationHeader = Invoke-RestMethod -Uri $CurrentContext.Eval('https://login.microsoftonline.com/#{AzureTenantId}/oauth2/token') -UseBasicParsing -Method Post -Body @{
        "grant_type" = "client_credentials"
        "resource" = "https://management.core.windows.net/"
        "client_id" = $CurrentContext.Get('ServicePrincipalClientId')
        "client_secret" = $CurrentContext.Get('ServicePrincipalClientSecret')
        } | % { $_.token_type + ' ' + $_.access_token }

    $containerSas = [uri]::new((Invoke-RestMethod -Uri 'https://mscompute2.iaas.ext.azure.com/api/Compute/VmExtensions/GetTemporarySas/' -UseBasicParsing -Headers @{
        [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = $authorizationHeader
    }))
    
    $blobContainer = [Microsoft.WindowsAzure.Storage.Blob.CloudBlobContainer]::new($containerSas)
    
    $blob = $blobContainer.GetBlockBlobReference([System.IO.Path]::GetFileName($Path))
    $blob.UploadFromFile(($Path | Convert-Path), [System.IO.FileMode]::Open)
    
    $blob.Uri.AbsoluteUri + $containerSas.Query
}