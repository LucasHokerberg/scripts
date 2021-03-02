<#

This script starts a Citrix session with the help of storebrowse.
It logs the session launch time in a log file named after the application or desktop launched.
In the Citrix session, the log_citrix_session script must be run to log the logon time and end the session.

Any errors are logged in a separate error log.

Usage: .\start_citrix_session.ps1 -AppName <Name of application(s) or desktop(s)>
Example: .\start_citrix_session.ps1 -AppName "My App 1","My App2","My Desktop"

Created: 2021-02-17
Author: lucas@hokerberg.com

#>

# Fetch parameters
param (
    [string[]] $AppName
)

# Define static paremeters
$userLogin = "robotuser"
$userPassword = "robotpwd"
$userDomain = "domain.ltd"
$storeUrl = "https://citrix.domain.ltd/Citrix/Store/discovery"

# Repeat for each app name
foreach ($app in $AppName) {   
    
    # Start logging
    "===== BEGIN =====" > "$($app).log"

    # Launch new Citrix session
    "Starting new Citrix session" >> "$($app).log"
    "<start>$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</start>" >> "$($app).log"
    Start-Process -FilePath "C:\Program Files (x86)\Citrix\ICA Client\AuthManager\storebrowse.exe" -ArgumentList @("-U $($userLogin)", "-P $($userPassword)", "-D $($userDomain)", "-S `"$($app)`"", $storeUrl)

    # Wait for session to log
    "Waiting for session to log..." >> "$($app).log"
    $retry = 0
    while ((Select-String -Path "$($app).log" -Pattern "<end>").LineNumber -lt 1) {
    
        $retry = $retry + 1

        if ($retry -lt 7) {
        
            Start-Sleep -Seconds 15
    
        } else {

            "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Citrix session taking too long time to log!" >> "$($app).err"
            "Citrix session taking too long time to log!" >> "$($app).log"
            exit 1
        }
    }

    # Allow session to complete logging
    Start-Sleep -Seconds 1

    # Done
    "===== END =====" >> "$($app).log"
}

exit 0
