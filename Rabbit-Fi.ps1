function Install-RabbitMQ
{
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$exePath,
        
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$rabbitMQEXE,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$erlangEXE,


		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$rabbitMQDBUser,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$rabbitMQDBPass	
		
    )

        $rabbitMQInstallPath = "C:\Program Files\RabbitMQ Server"
        $rabbitMQServerInstallPath = "C:\Program Files\RabbitMQ Server\rabbitmq_server-3.7.26"
		$erlangInstallPath = "C:\Program Files\erl10.7"
         
        if(!(Test-Path $rabbitMQInstallPath ))
        {
            $erlangFullPath =  Join-Path $exePath $erlangEXE
            Write-Host "Installing $erlangFullPath"
            $argumentList = "/S"
            Start-Process -FilePath $erlangFullPath -ArgumentList "$argumentList" -Wait

            $rabbitMQFullPath =  Join-Path $exePath $rabbitMQEXE
            Write-Host "Installing $rabbitMQFullPath"
            $proc = Start-Process -FilePath $rabbitMQFullPath -ArgumentList "$argumentList" -Wait:$false -Passthru
            Wait-Process -Id $proc.Id
			
			New-NetFirewallRule -DisplayName "RabbitMQ" -Direction Inbound -LocalPort 4369 -Protocol TCP -Action Allow
			
			New-Item -ItemType file "$rabbitMQInstallPath\rabbitmq.conf"

			Add-Content  "$rabbitMQInstallPath\rabbitmq.conf" "log.file.level = error"

			Add-Content  "$rabbitMQInstallPath\rabbitmq.conf" "log.file.rotation.date = `$D0"

			Add-Content  "$rabbitMQInstallPath\rabbitmq.conf" "log.file.rotation.count = 10 "
			
			[Environment]::SetEnvironmentVariable("Path", "$env:Path;$rabbitMQInstallPath", "Machine")

			[Environment]::SetEnvironmentVariable("Path", "$env:Path;$rabbitMQServerInstallPath\sbin", "Machine")

			[Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $rabbitMQInstallPath,"Machine")

			[Environment]::SetEnvironmentVariable("RABBITMQ_CONFIG_FILE", "$rabbitMQInstallPath\rabbitmq.conf","Machine")

			[Environment]::SetEnvironmentVariable("ERLANG_HOME", $erlangInstallPath,"Machine")
			[Environment]::SetEnvironmentVariable("Path", "$env:Path;$erlangInstallPath\bin", "Machine")
			[Environment]::SetEnvironmentVariable("Path", "$env:Path;$erlangInstallPath\bin", "User")

			$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
			$env:ERLANG_HOME = $erlangInstallPath
            Set-Location "$rabbitMQServerInstallPath\sbin\"
			$ErrorActionPreference = "SilentlyContinue"
             .\rabbitmqctl start_app
            $ErrorActionPreference = "Continue" 
            .\rabbitmq-service.bat install

        }
        $env:ERLANG_HOME = $erlangInstallPath
        Set-Location "$rabbitMQServerInstallPath\sbin\"
     
        if ((Get-Service -Name RabbitMQ).Status -ne "Running")
        {
           .\rabbitmq-service.bat start    
           .\rabbitmq-service.bat restart 
        }
         $ErrorActionPreference = "SilentlyContinue"
         .\rabbitmqctl start_app
         .\rabbitmqctl add_user $rabbitMQDBUser $rabbitMQDBPass
         .\rabbitmqctl set_permissions "$rabbitMQDBPass" .* .* .*
		 #delete user always throws error on rerun  so running as a process
		 Start-Process -FilePath .\rabbitmqctl -ArgumentList "delete_user guest"
         $ErrorActionPreference = "Continue" 
		 
		 
}

Install-RabbitMQ -exePath $exePath -rabbitMQEXE $rabbitMQEXE -erlangEXE $erlangEXE -rabbitMQDBUser $rabbitMQDBUser -rabbitMQDBPass $rabbitMQDBPass