<#

This script writes to a log file as a proof that the Citrix session is actually started.

Usage: .\log_citrix_session.ps1

Created: 2021-03-05
Author: lucas@hokerberg.com

#>

# Define static variables
$logFile = "\\Client\C$\Robot\check_citrix_logon\My App.log"

Get-Date -Format "yyyy-MM-dd HH:mm:ss" >> $logFile

Write-Host "Script will finish and logout in 5 seconds!"
Start-Sleep -Seconds 5

logoff
exit 0
