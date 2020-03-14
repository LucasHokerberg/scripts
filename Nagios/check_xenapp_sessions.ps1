# -------------------------------------------------------------------------------------------------------------
# Script to monitor XenApp sessions in a selected state.
# NSClient must run as a user with read access to the XenApp farm.
#
# Usage:
# .\check_xenapp_sessions.ps1 -SessionState <SessionState> -Warning <WarningThreshold> -Critical <CriticalThreshold>
#
# Valid session states:
# Connected, Active and Disconnected
#
# Example:
# .\check_xenapp_sessions.ps1 -SessionState Active -Warning 90 -Critical 100
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [string] $SessionState,
    [int] $Warning,
    [int] $Critical
)

# Load modules
Add-PSSnapin Citrix*

# Clear old errors
$error.clear()

# Try get sessions
try {

    $sessions = Get-BrokerSession -SessionState $SessionState

} catch {

    Write-Host "UNKOWN: Unable to get sessions!"
    exit 3
}

# Successfully got sessions
if (!$error) {

    # If sessions is critical
    if ($($sessions.Count) -ge $Critical) {
        
        # Return output
        Write-Host "Critical: $($sessions.Count) $($SessionState.ToLower()) sessions|Sessions=$($sessions.Count);$Warning;$Critical;0"
        exit 2
     
     # If sessions is warning
     } elseif ($($sessions.Count) -ge $Warning) {
        
        # Return output
        Write-Host "Warning: $($sessions.Count) $($SessionState.ToLower()) sessions|Sessions=$($sessions.Count);$Warning;$Critical;0"
        exit 1
     
     # If sessions is OK
     } elseif ($($sessions.Count) -lt $Warning) {

        # Return output
        Write-Host "OK: $($sessions.Count) $($SessionState.ToLower()) sessions|Sessions=$($sessions.Count);$Warning;$Critical;0"
        exit 0
    }
}

Write-Host "UNKOWN: An unkown error has occured!"
exit 3