<#

This script "rotates" Virtual Apps servers. I.e. the following:
1. Boot up standby servers and take them out of maintenance mode
2. Put active servers in maintenance mode
3. Inform users on active servers to sign out (the script will send out a message with a standard text, plus any optional text, three times periodically during the delay time.)
4. Shut down active servers

If a server is not booting up, the script will abort and send out a mail notification.
After a successfull rotation, the script will send out a mail notification.

Author: lucas@hokerberg.com

Usage:
.\Rotate-VirtualAppsServers.ps1 -Config <INI File>

Arguments:
Config - Path to the INI file with parameters

Example:
.\Rotate-VirtualAppsServers.ps1 -Config MySettings.ini

- INI File -

[Global]
gDelay=<Delay in minutes until the active servers will shutdown>
gMessage=<Relative path to a text file containing an extra message to be sent out to sessions on servers to be set in standby>
gInterval=<Weekly or Monthly (used to determine if Even and Odd should be calculated based on week number or month)>

[Even]
eActive=<List of servers to be powered on and active after the rotation (seperated by comma)>
eStandby=<List of servers to shutdown and put as standby after the rotation (separated by comma)>

[Odd]
oActive=<List of servers to be powered on and active after the rotation (seperated by comma)>
oStandby=<List of servers to shutdown and put as standby after the rotation (separated by comma)>

#>

# Fetch parameters
param (
    [string] $Config
)

# Define INI parameters
Get-Content $Config | ForEach-Object -Begin {$c=@{}} -Process { $k = [regex]::split($_,"="); if (($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $c.Add($k[0], $k[1]) } }
$Delay = $c.gDelay
$Message = $c.gMessage

# Define static parameters
$smtpFrom = "no-reply@domain.com" # Sender address
$smtpTo = @("logs@domain.com") # Send mail to (separate multiple recipients with comma)
$smtpServer = "smtp.domain.com" # Your SMTP server

# Define Active and Standby servers
if ($c.gInterval -eq "Weekly") {

    if ((Get-Date -UFormat %V) % 2 -eq 0 ) {

        # Even week
        $Active = $c.eActive -split ","
        $Standby = $c.eStandby -split ","

    } elseif ((Get-Date -UFormat %V) % 2 -eq 1 ) {

        # Odd week
        $Active = $c.oActive -split ","
        $Standby = $c.oStandby -split ","
    }

} elseif ($c.gInterval -eq "Monthly") {

    if ((Get-Date -UFormat %m) % 2 -eq 0 ) {

        # Even month
        $Active = $c.eActive -split ","
        $Standby = $c.eStandby -split ","

    } elseif ((Get-Date -UFormat %m) % 2 -eq 1 ) {

        # Odd month
        $Active = $c.oActive -split ","
        $Standby = $c.oStandby -split ","
    }

} else {

    # Abort if bad config
    exit
}

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
:powerOff foreach ($server in $Standby) {

    # Power off server and wait for power off
    $i = 0
    New-BrokerHostingPowerAction -MachineName $server -Action Shutdown
    while ((Get-BrokerMachine -HostedMachineName $server).PowerState -ne "Off") {
        
        $i++
        Start-Sleep -Seconds 15

        # Continue even if server is not powering off
        if ($i -eq 16) {
            
            continue powerOff
        }
    }
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
