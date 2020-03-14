# -------------------------------------------------------------------------------------------------------------
# Script to "rotate" Virtual Apps servers. I.e. the following:
# 1. Boot up standby servers and take them out off maintanance mode
# 2. Put active servers in maintanance mode
# 3. Inform users on active servers to sign out
# 4. Shut down active servers
#
# After a complete rotation, the script will send out a mail notification.
#
# Usage:
# .\Rotate-VirtualAppsServers.ps1 -Active <Servers> -Standby <Servers> -Delay <Minutes> -Message <Filename>
#
# Arguments:
# Active - List of servers to be powered on and active after the rotation (seperated by comma).
# Standby - List of servers to shutdown and put as standby after the rotation (separated by comma).
# Delay - Delay in minutes until the active servers will be rebooted.
# Message - Relative path to a text file containing an extra message to be sent out to sessions on servers to be set in standby.
#
# Notification:
# The script will send out a message with a standard text, plus any optional text, 3 times periodically during the delay time.
#
# Example:
# .\Rotate-VirtualAppsServers.ps1 -Active VDA01,VDA02 -Standby VDA03,VDA04 -Delay 60 -Message message.txt
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [array] $Active,
    [array] $Standby,
    [int] $Delay,
    [string] $Message
)

# Define mail parameters
$smtpFrom = "VDA@domain.com" # Sender address
$smtpTo = @("admin@domain.com") # Send mail to (separate multiple recipients with comma)
$smtpServer = "smtp.domain.local" # Your SMTP server

# Load modules
Add-PSSnapin Citrix*

# Repeat for each server to be active after the rotation
foreach ($server in $Active) {
    
    # Power on
    New-BrokerHostingPowerAction -MachineName $server -Action TurnOn

    # While the server is not registered
    while ((Get-BrokerMachine -MachineName $env:userdomain\$server).RegistrationState -ne "Registered") {
        
        # Wait
        Start-Sleep -Seconds 15
    }

    # Exit maintanance mode
    Set-BrokerMachineMaintenanceMode -InputObject $env:userdomain\$server $false
}

# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Enter maintanance mode
    Set-BrokerMachineMaintenanceMode -InputObject $env:userdomain\$server $true
}

# Calculate rotation time and message interval
$rotateTime = (Get-Date).AddMinutes($Delay)
$msgInterval = $Delay*60/3

# If message argument is set
if ($Message) {

    # Get message file content
    $msg = Get-Content $Message | Out-String
}

# -- FIRST MESSAGE INTERVAL --
# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Get sessisons
    $sessions = Get-BrokerSession -HostedMachineName $server

    # If there are any sessions
    if ($sessions) {

        # Send message
        Send-BrokerSessionMessage $sessions `
            -MessageStyle Exclamation `
            -Title "Maintanance window at $($rotateTime.ToString("HH:mm")) (in $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minutes)" `
            -Text "Warning 1 of 3.`n`n$msg"
    }
}

# Wait until second message interval
Start-Sleep -Seconds $msgInterval

# -- SECOND MESSAGE INTERVAL --
# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Get sessisons
    $sessions = Get-BrokerSession -HostedMachineName $server

    # If there are any sessions
    if ($sessions) {

        # Send message
        Send-BrokerSessionMessage $sessions `
            -MessageStyle Exclamation `
            -Title "Maintanance window at $($rotateTime.ToString("HH:mm")) (in $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minutes)" `
            -Text "Warning 2 of 3.`n`n$msg"
    }
}

# Wait until third message interval
Start-Sleep -Seconds $msgInterval

# -- THIRD MESSAGE INTERVAL --
# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Get sessisons
    $sessions = Get-BrokerSession -HostedMachineName $server

    # If there are any sessions
    if ($sessions) {

        # Send message
        Send-BrokerSessionMessage $sessions `
            -MessageStyle Exclamation `
            -Title "Maintanance window at $($rotateTime.ToString("HH:mm")) (in $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minutes)" `
            -Text "Warning 3 of 3.`n`n$msg"
    }
}

# Wait until rotation time
Start-Sleep -Seconds $msgInterval

# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Power off
    New-BrokerHostingPowerAction -MachineName $server -Action Shutdown
}

# Send email notification
[string[]]$smtpTo = $smtpTo.Split(",")
Send-MailMessage -From $smtpFrom -To $smtpTo -Subject "Virtual Apps Server Rotation" -Body "The Virtual Apps server rotation is complete.`n`nNew active servers: $Active`n`nNew standby servers: $Standby`n`nPlease verify!" -SmtpServer $smtpServer