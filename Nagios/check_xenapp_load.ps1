# -------------------------------------------------------------------------------------------------------------
# Script to monitor XenApp load on shared VDAs.
# NSClient must run as a user with read access to the XenApp farm.
#
# Usage:
# .\check_xenapp_load.ps1 -Warning <WarningThreshold> -Critical <CriticalThreshold>
#
# Example:
# .\check_xenapp_load.ps1 -Warning 80 -Critical 90
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [int] $Warning,
    [int] $Critical
)

# Load modules
Add-PSSnapin Citrix*

# Clear old errors
$error.clear()

# Try get load
try {

    $vdas = Get-BrokerMachine -DesktopKind Shared

} catch {

    Write-Host "UNKOWN: Unable to get load!"
    exit 3
}

# Successfully got load
if (!$error) {

    # Loop for each VDA
    foreach ($vda in $vdas) {

        # Calculate and round the load
        $load = [math]::Round($vda.LoadIndex/100)

        # If load is critical
        if ($($vda.LoadIndex/100) -ge $Critical) {
        
            $returnCritical = "$returnCritical $($vda.HostedMachineName) has $load% load"
            $returnPerf = "$returnPerf $($vda.HostedMachineName)=$load;$Warning;$Critical;0"
     
         # If load is warning
         } elseif ($($vda.LoadIndex/100) -ge $Warning) {
        
            $returnWarning = "$returnWarning $($vda.HostedMachineName) has $load% load"
            $returnPerf = "$returnPerf $($vda.HostedMachineName)=$load;$Warning;$Critical;0"
     
         # If load is OK
         } elseif ($($vda.LoadIndex/100) -lt $Warning) {

            $returnOk = "$returnOk $($vda.HostedMachineName) has $load% load"
            $returnPerf = "$returnPerf $($vda.HostedMachineName)=$load;$Warning;$Critical;0"
        }
    }

    # If critical
    if ($returnCritical) {

        Write-Host "Critical:$returnCritical |$returnPerf"
        exit 2

    # If warning
    } elseif ($returnWarning) {
    
        Write-Host "Warning:$returnWarning |$returnPerf"
        exit 1

    # If OK
    } elseif ($returnOk) {
    
        Write-Host "OK:$returnOk |$returnPerf"
        exit 0

    # If no status at all
    } else {

        Write-Host "UNKOWN: An unkown error has occured!"
        exit 3
    }

# Error while reading load
} else {

    Write-Host "UNKOWN: An unkown error has occured!"
    exit 3
}

Write-Host "UNKOWN: An unkown error has occured!"
exit 3