<#

This script writes to a log file as a proof that the Citrix session is actually started.

Usage: .\log_citrix_session.ps1

Created: 2021-02-17
Author: lucas.hokerberg@gelita.com

#>

# Define static variables
$logFile = "\\Client\C$\Script\check_citrix_logon\myapp.log"

"<end>$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</end>" >> $logFile
"Citrix session successfully started!" >> $logFile

Write-Host "Script will finish and logout in 5 seconds!"
Start-Sleep -Seconds 5

logoff
exit 0
