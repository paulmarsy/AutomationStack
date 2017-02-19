function New-SelfSignedCertificateEx {
    param(
		[Parameter(Mandatory)]$Subject,
        [Parameter(Mandatory)]$FriendlyName
    )

	$name = New-Object -ComObject X509Enrollment.CX500DistinguishedName
    const XCN_CERT_NAME_STR_NONE = (0x0)
	$name.Encode($Subject, [int]$XCN_CERT_NAME_STR_NONE)

	$privateKey = New-Object -ComObject X509Enrollment.CX509PrivateKey
	$privateKey.ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0"
    $AlgOID = New-Object -ComObject X509Enrollment.CObjectId
	$AlgOID.InitializeFromValue([Security.Cryptography.Oid]::FromFriendlyName('RSA', [Security.Cryptography.OidGroup]::PublicKeyAlgorithm).Value)
    $privateKey.Algorithm = $AlgOID
    const XCN_AT_KEYEXCHANGE = (0x1)
	$privateKey.KeySpec = [int]$XCN_AT_KEYEXCHANGE
	$PrivateKey.Length = 2048
    const XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG = (0x2)
	$PrivateKey.ExportPolicy = [int]$XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG
	$PrivateKey.Create()

    $kuExtension = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
    $kuExtension.InitializeEncode([int][Security.Cryptography.X509Certificates.X509KeyUsageFlags]'DataEncipherment, KeyEncipherment, DigitalSignature')
    $kuExtension.Critical = $true

    $ekuOids = New-Object -ComObject "X509Enrollment.CObjectIds"
    # Server Authentication (1.3.6.1.5.5.7.3.1)
    $serverAuthOid = New-Object -ComObject X509Enrollment.CObjectId
    $serverAuthOid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
    $ekuOids.Add($serverauthOid)
    # Client Authentication (1.3.6.1.5.5.7.3.2)
    $clientAuthOid = New-Object -ComObject X509Enrollment.CObjectId
    $clientAuthOid.InitializeFromValue("1.3.6.1.5.5.7.3.2")
    $ekuOids.Add($clientAuthOid)
  
    $ekuExtension = New-Object -ComObject "X509Enrollment.CX509ExtensionEnhancedKeyUsage"
    $ekuExtension.InitializeEncode($ekuOids)

	$Cert = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
    const ContextUser = (0x1)
    $Cert.InitializeFromprivateKey($ContextUser, $privateKey, "")
	$Cert.Subject = $name
	$Cert.Issuer = $name
	$Cert.NotBefore = (Get-Date).AddDays(-1)
	$Cert.NotAfter = (Get-Date).AddDays(365)
	$SigOID = New-Object -ComObject X509Enrollment.CObjectId
	$SigOID.InitializeFromValue([Security.Cryptography.Oid]::FromFriendlyName('SHA256', [Security.Cryptography.OidGroup]::HashAlgorithm).Value)
	$Cert.SignatureInformation.HashAlgorithm = $SigOID
    $Cert.X509Extensions.Add($kuExtension)
    $Cert.X509Extensions.Add($ekuExtension)
	$Cert.Encode()
	
	$enrollment = New-Object -ComObject X509Enrollment.CX509Enrollment
	$enrollment.InitializeFromRequest($Cert)
	$enrollment.CertificateFriendlyName = $FriendlyName
    const XCN_CRYPT_STRING_BASE64HEADER = (0x0)
    const XCN_CRYPT_STRING_BASE64 = (0x1)
    const XCN_CRYPT_STRING_BINARY = (0x2)
    const XCN_CRYPT_STRING_NOCRLF = (0x40000000)
	$request = $enrollment.CreateRequest($XCN_CRYPT_STRING_BASE64HEADER)

    const AllowUntrustedCertificate = (0x2)
	$enrollment.InstallResponse($AllowUntrustedCertificate, $request, $XCN_CRYPT_STRING_BASE64HEADER,"")

    const PFXExportChainWithRoot = (0x2)
    $pfx = $enrollment.CreatePFX("",$PFXExportChainWithRoot,$XCN_CRYPT_STRING_BASE64 -bor $XCN_CRYPT_STRING_NOCRLF)

    $x509Cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new([System.Convert]::FromBase64String($pfx))
     Remove-Item (Join-Path 'Cert:\CurrentUser\My\' $x509Cert.Thumbprint)
	
    @{
        Base64Pfx = $pfx
        Thumbprint = $x509Cert.Thumbprint
        StartDate = $x509Cert.GetEffectiveDateString()
        EndDate = $x509Cert.GetExpirationDateString()
    }
}