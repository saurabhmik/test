function Install-ApacheHttpd
{
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$packagePath,
        
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$installPath,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$configPath		
    )
	
	$logDIR = "C:\app\Logs"
	if(!(Test-Path $logDIR) )
	{
		New-Item -ItemType Directory -Path $logDIR -force
	}
	
	Write-Host $configPath
	
	if(!(Test-Path $installPath) )
	{
		New-Item -ItemType Directory -Path $installPath -force
		Copy-Item (Join-Path $packagePath "\*") $installPath -recurse -force
		
		Copy-Item (Join-Path $configPath "httpd.conf") (Join-Path $installPath "conf") -force
		Copy-Item (Join-Path $configPath "mod_wsgi.so") (Join-Path $installPath "modules") -force
	}  
	
	Set-Location (Join-Path $installPath "bin")
	./httpd.exe -k install
	Start-Service "Apache2.4"
}

Install-ApacheHttpd -packagePath "#{Octopus.Action[Deploy ApacheHttpd].Output.Package.InstallationDirectoryPath}" -installPath "c:\Apache24" -configPath "#{Octopus.Action[Deploy ApacheConfig].Output.Package.InstallationDirectoryPath}"
 
