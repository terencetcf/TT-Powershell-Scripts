<#
.Synopsis
	Install required certificates on IIS
.EXAMPLE
	./import-certificate.ps1
#>
function Import-Certificate($certificatePath, $password, $certstore, $folders)
{
	foreach ($s in $folders)
	{
		Write-Host "Importing $certificatePath into $certstore\$s"
		
		$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$cert.import($certificatePath, $password, "Exportable,PersistKeySet")

		$store = New-Object System.Security.Cryptography.X509Certificates.X509Store($s, $certstore)			

		$store.open("MaxAllowed")
		$store.add($cert)
		$store.close()
		
		# give access for everyone to the private key
		$tp = $cert.Thumbprint
		$uname="everyone"
		$keyname = (((gci cert:\LocalMachine\my | ? {$_.thumbprint -like $tp}).PrivateKey).CspKeyContainerInfo).UniqueKeyContainerName
		$keypath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
		$fullpath = $keypath+$keyname
		icacls $fullpath /grant $uname`:W
	}
}

function Import-ApiCertificates
{	
	$path = [System.IO.Path]::GetFullPath(("$currentDirectory\certs"))
	$certificatePassword="password"	
	Write-Host "Importing all certificates in '$path'"
	ls "$path" -filter *.pfx | foreach {
		Import-Certificate "$($_.FullName)" $certificatePassword "LocalMachine" @("My")
	}
}

$currentDirectory = $PSScriptRoot
pushd $currentDirectory

if(Get-Module -Name "WebAdministration"){
	Remove-Module WebAdministration	
}

Import-Module WebAdministration
Import-ApiCertificates

popd
