<#

This script starts a Citrix session with the help of storebrowse.
It logs the session launch time in a log file named after the application or desktop launched.
In the Citrix session, the log_citrix_session script must be run to log the logon time and end the session.

Any errors are logged in a separate error log.

Usage: .\start_citrix_session.ps1 -AppName <Name of application(s) or desktop(s)>
Example: .\start_citrix_session.ps1 -AppName "My App 1","My App2","My Desktop"

Created: 2021-02-17
Author: lucas.hokerberg@gelita.com

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

    # Abort if a session is already running
    if ((Get-Process -Name "CDViewer" -ErrorAction SilentlyContinue).Count -gt 0) {

        "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Citrix session already running! Killing session and aborting." >> "error.log"
        "Citrix session already running! Killing session and aborting." >> "$($app).log"
        Stop-Process -Name "CDViewer" -Force
        exit 1
    }

    # Launch new Citrix session
    "Starting new Citrix session" >> "$($app).log"
    "<start>$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</start>" >> "$($app).log"
    Start-Process -FilePath "C:\Program Files (x86)\Citrix\ICA Client\AuthManager\storebrowse.exe" -ArgumentList @("-U $($userLogin)", "-P $($userPassword)", "-D $($userDomain)", "-S `"$($app)`"", $storeUrl)

    # Wait for session to start
    "Waiting for session to start..." >> "$($app).log"
    $retry = 0
    while ((Get-Process -Name "CDViewer" -ErrorAction SilentlyContinue).Count -eq 0) {
    
        $retry = $retry + 1

        if ($retry -lt 6) {
        
            Start-Sleep -Seconds 1
    
        } else {

            "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Citrix Workspace not starting!" >> "error.log"
            "Citrix Workspace not starting!" >> "$($app).log"
            exit 1
        }
    }

    # Wait for session to close
    "Waiting for session to close..." >> "$($app).log"
    $retry = 0
    while ((Get-Process -Name "CDViewer" -ErrorAction SilentlyContinue).Count -gt 0) {
    
        $retry = $retry + 1

        if ($retry -lt 19) {
        
            Start-Sleep -Seconds 5
    
        } else {

            "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Citrix session taking too long time!" >> "error.log"
            "Citrix session taking too long time!" >> "$($app).log"
            exit 1
        }
    }

    # Done
    "===== END =====" >> "$($app).log"
}

exit 0