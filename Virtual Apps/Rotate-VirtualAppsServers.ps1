<#

This script "rotates" Virtual Apps servers. I.e. the following:
1. Boot up standby servers and take them out of maintenance mode
2. Put active servers in maintenance mode
3. Inform users on active servers to sign out
4. Shut down active servers

If a server is not booting up, the script will abort and send out a mail notification.
After a successfull rotation, the script will send out a mail notification.

Author: lucas@hokerberg.com

Usage:
.\Rotate-VirtualAppsServers.ps1 -Active <Servers> -Standby <Servers> -Delay <Minutes> -Message <Filename>

Arguments:
Active - List of servers to be powered on and active after the rotation (seperated by comma).
Standby - List of servers to shutdown and put as standby after the rotation (separated by comma).
Delay - Delay in minutes until the active servers will shutdown.
Message - Relative path to a text file containing an extra message to be sent out to sessions on servers to be set in standby.

Notification:
The script will send out a message with a standard text, plus any optional text, three times periodically during the delay time.

Example:
.\Rotate-VirtualAppsServers.ps1 -Active VDA01,VDA02 -Standby VDA03,VDA04 -Delay 60 -Message info.txt

#>

# Fetch parameters
param (
    [array] $Active,
    [array] $Standby,
    [int] $Delay,
    [string] $Message
)

# Define static parameters
$smtpFrom = "no-reply@domain.com" # Sender address
$smtpTo = @("logs@domain.com") # Send mail to (separate multiple recipients with comma)
$smtpServer = "smtp.domain.com" # Your SMTP server

# Load required modules
Add-PSSnapin Citrix*

# Repeat for each server to be active after the rotation
foreach ($server in $Active) {
    
    # Power on server and wait for registration
    $i = 0
    New-BrokerHostingPowerAction -MachineName $server -Action TurnOn
    while ((Get-BrokerMachine -HostedMachineName $server).RegistrationState -ne "Registered") {
        
        $i++
        Start-Sleep -Seconds 15

        # Abort if server is not registering
        if ($i -eq 16) {
            
            [string[]]$smtpTo = $smtpTo.Split(",")
            Send-MailMessage `
                -From $smtpFrom `
                -To $smtpTo `
                -SmtpServer $smtpServer `
                -Subject "Virtual Apps Server Rotation" `
                -Body "The Virtual Apps server rotation was aborted. The server $($server) never registered."
            exit
        }
    }

    # Exit maintenance
    Set-BrokerMachineMaintenanceMode -InputObject "$($env:userdomain)\$($server)" $false

    # Abort if server is still in maintenance mode
    if (-not (Get-BrokerMachine -HostedMachineName $server -InMaintenanceMode $false)) {

        [string[]]$smtpTo = $smtpTo.Split(",")
        Send-MailMessage `
            -From $smtpFrom `
            -To $smtpTo `
            -SmtpServer $smtpServer `
            -Subject "Virtual Apps Server Rotation" `
            -Body "The Virtual Apps server rotation was aborted. The server $($server) is still in maintenance mode."
        exit
    }
}

# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Enter maintenance
    Set-BrokerMachineMaintenanceMode -InputObject "$($env:userdomain)\$($server)" $true

    # Abort if server is still not in maintenance mode
    if (-not (Get-BrokerMachine -HostedMachineName $server -InMaintenanceMode $true)) {

        [string[]]$smtpTo = $smtpTo.Split(",")
        Send-MailMessage `
            -From $smtpFrom `
            -To $smtpTo `
            -SmtpServer $smtpServer `
            -Subject "Virtual Apps Server Rotation" `
            -Body "The Virtual Apps server rotation was aborted. The server $($server) could not enter maintenance mode."
        exit
    }
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
            -Title "Servicefönster kl. $($rotateTime.ToString("HH:mm")) (om $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minuter)" `
            -Text "Varning 1 av 3.`n`n$($msg)"
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
            -Title "Servicefönster kl. $($rotateTime.ToString("HH:mm")) (om $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minuter)" `
            -Text "Varning 2 av 3.`n`n$($msg)"
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
            -Title "Servicefönster kl. $($rotateTime.ToString("HH:mm")) (om $([math]::Round(($rotateTime-(Get-Date)).TotalMinutes)) minuter)" `
            -Text "Varning 3 av 3.`n`n$($msg)"
    }
}

# Wait until rotation time
Start-Sleep -Seconds $msgInterval

# Repeat for each server to be standby after the rotation
foreach ($server in $Standby) {

    # Power off
    New-BrokerHostingPowerAction -MachineName $server -Action Shutdown
}

# Get current server status
$status = Get-BrokerMachine -DesktopKind Shared | Select-Object @{N="Server";E={$_.HostedMachineName}}, @{N="Maintenance Mode";E={$_.InMaintenanceMode}}, @{N="Power State";E={$_.PowerState}}, @{N="Status";E={$_.RegistrationState}}, @{N="Sessions";E={$_.SessionCount}} | ConvertTo-Html -Head "<style>table { padding-right: 25px; text-align: left }</style>"

# Send email notification
[string[]]$smtpTo = $smtpTo.Split(",")
Send-MailMessage `
    -From $smtpFrom `
    -To $smtpTo `
    -SmtpServer $smtpServer `
    -BodyAsHtml `
    -Subject "Virtual Apps Server Rotation" `
    -Body "<h1>Virtual Apps Server Rotation</h1>
           <p>The Virtual Apps server rotation is complete.</p>
           <p><strong>New active servers:</strong> $($Active)<br>
           <strong>New standby servers:</strong> $($Standby)</p>
           <h2>Current server status</h2>
           $($status)"
exit
