# -------------------------------------------------------------------------------------------------------------
# Script to monitor Nagios server status.
# It browses the servers JSON status page using the provided credentials and parses the content.
# If the status page does not match the desired state, an e-mail is beeing sent.
#
# A log file is beeing (re)created every time the script runs.
# You can monitor the log file in Nagios to verify that this script is actually running.
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Define Nagios parameters
$url = "https://icinga.domain.local/cgi-bin/icinga/extinfo.cgi?jsonoutput" # URL to the Nagios JSON status page (htts://your-server.local/cgi-bin/extinfo.cgi?jsonoutput)
$username = "admin" # Username to Nagios web
$password = "password" # Password to the above username

# Define mail parameters
$smtpFrom = "NagiosSupervisor@domain.com" # Sender address
$smtpTo = @("admin1@domain.com,admin2@domain.com") # Send mail to (separate multiple recipients with comma)
$smtpServer = "smtp.domain.local" # Your SMTP server

# Prepare for web browsing
$webClient = New-Object System.Net.WebClient
$webclient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
$webClient.Headers.Add("user-agent", "PowerShell Script")

# Browse the web
$status = $webClient.DownloadString($url)

# Check for status
if (
        ($status -like '*"notifications_enabled": true*') -and
        ($status -like '*"service_checks_being_executed": true*') -and
        ($status -like '*"passive_service_checks_being_accepted": true*') -and
        ($status -like '*"host_checks_being_executed": true*') -and
        ($status -like '*"passive_host_checks_being_accepted": true*') -and
        ($status -like '*"event_handlers_enabled": true*') -and
        ($status -like '*"flap_detection_enabled": true*') -and
        ($status -like '*"performance_data_being_processed": true*')
    ) {

    # Everyhing is green
    Write-Output "Nagios server status OK!" > ".\NagiosSupervisor.log"

} else {

    # Something is not right
    Write-Output "Something is not right! Sending e-mail..." > ".\Check-Nagios.log"
    [string[]]$smtpTo = $smtpTo.Split(",")
    Send-MailMessage -From $smtpFrom -To $smtpTo -Subject "Nagios Server Status Alert!" -Body "The Nagios server does not seems to function properly. Check the server health!" -SmtpServer $smtpServer
}