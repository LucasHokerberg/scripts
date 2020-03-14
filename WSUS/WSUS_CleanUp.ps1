# ----------------------------------------------------------------------------
# This script cleans up the WSUS contect folder and removes oboslete downloads.
# It also removes old and inactive computers from the WSUS database.
#
# Author: lucas@hokerberg.com
# ----------------------------------------------------------------------------

# Define log file
$logLocation = "C:\Scripts\WSUS_cleanup.log"

# Some basics
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"

# Start WSUS clean up
Start-Transcript -Path $logLocation -Append
echo "$(Get-Date): Starting WSUS Clean up..."
Invoke-WsusServerCleanup -DeclineSupersededUpdates -DeclineExpiredUpdates -CleanupObsoleteUpdates -CleanupUnneededContentFiles -CompressUpdates -CleanupObsoleteComputers
echo "$(Get-Date): WSUS Clean up finish!"

# Done
Stop-Transcript