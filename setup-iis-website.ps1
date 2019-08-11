<#
.Synopsis
	Sets up IIS
.Description
	create the IIS website.	
.EXAMPLE
	.
#>

#region Setup IIS Powershell Modules

function SetupModules()
{
	Print-Heading "Importing IIS modules"
	if(Get-Module -Name "WebAdministration"){
		Remove-Module WebAdministration	
	}
	
	Import-Module WebAdministration
}

#endregion

#region Delete Existing Websites

function DeleteWebsite([string]$site) 
{
	if (Test-Path "iis:\sites\$site") {
		Write-Host "Deleting website: " $site 
		Remove-Item "iis:\sites\$site" -Recurse -Force
	}
}

function DeleteAppPool([string]$appPool)
{
	if (Test-Path "iis:\appPools\$appPool") {
		Write-Host "Deleting app pool: " $appPool
		Remove-Item "iis:\appPools\$appPool" -Recurse -Force
	}
}

#endregion

#region Create Log Folders

function CreateLogFolders()
{
	Print-Heading "Creating log folders"
	
	$logFolders = @("C:\Logs\TheWebsite\")

	foreach($logFolder in $logFolders)
	{
		if (-not (Test-Path "$logFolder")) {
			Write-Host "Creating folder '$logFolder'"
			md "$logFolder"
		}
	}
	
	Print-Success "Done!"
}

#endregion

#region Create App Pools

function CreateAppPool([string]$name) 
{
	Write-Host "Creating app pool - $name"
	$appPool = New-Item IIS:\AppPools\"$name"	
	$appPool.managedRuntimeVersion = "v4.0"
	$appPool.processModel.identityType = "ApplicationPoolIdentity"
	$appPool | Set-Item	
}

#endregion

#region Create Websites

function CreateRootWebsite([string]$directory, [string]$WebsiteAppPool, [string]$WebsitePath, [string]$WebsiteName) 
{
	Write-Host "Creating root website under app pool " 
	$path = [System.IO.Path]::GetFullPath(($directory + $WebsitePath))
	$binding = (@{protocol="http"; bindingInformation=":80:$WebsiteName"})	
	$webSite = New-Item "IIS:\sites\$WebsiteName" -physicalPath "$path" -bindings $binding -applicationPool $WebsiteAppPool
}

function CreateAdxVirtualDirectory([string]$irtualDirectoryName, [string]$WebsitePath)
{
	Write-Host "Creating virtual directory"
	New-Item "IIS:\sites\$VirtualDirectoryName\" + $directory -type VirtualDirectory -physicalPath $WebsitePath
}

function CreateChildWebsite([string]$physicalPath, [string]$parentName, [string]$childName, [string]$appPoolName) 
{
	Write-Host "Creating child website $childName under parent $parentName and app pool $appPoolName"
	$path = [System.IO.Path]::GetFullPath($physicalPath)
	$application = New-Item "IIS:\sites\$parentName\$childName" -physicalPath "$path" -type Application -applicationPool $appPoolName
}

#endregion

#region Start App Pools

function StartAppPool([string]$name)
{
	if((Get-WebAppPoolState $name).Value -ne 'Started')
    {
		Write-Host "Starting app pool - $name"
		Start-WebAppPool -Name $name
    }
}

#endregion

#region Utilities

function Print-Heading([string]$str)
{
	Write-Host ""
	Write-Host "$str" -ForegroundColor Black -BackgroundColor Yellow
	Write-Host ""
}

function Print-Success([string]$str)
{
	Write-Host ""
	Write-Host "$str" -ForegroundColor Black -BackgroundColor Green
	Write-Host ""
}

#endregion

$rootPath = $args[0]
Init $rootPath