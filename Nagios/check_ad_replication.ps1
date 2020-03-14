# -------------------------------------------------------------------------------------------------------------
# Script to monitor AD replication in Nagios.
#
# Usage:
# ./check_ad_replication.ps1 -ServerName <Domain Controller> -MaxDiffTime <Max minutes from last replication>
#
# Valid parameters for ServerName:
# - The name of a Domain Controller
# - "CheckAll" for all Domain Controllers in the forest
#
# Examples:
# ./check_ad_replication.ps1 -ServerName CheckAll -MaxDiffTime 60
# ./check_ad_replication.ps1 -ServerName localhost -MaxDiffTime 10
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [string] $ServerName,
    [int] $MaxDiffTime
)

# Get status of replications
if ($ServerName -eq "CheckAll") {

    $replications = repadmin /showrepl * /csv | ConvertFrom-Csv

} else {

    $replications = repadmin /showrepl $ServerName /csv | ConvertFrom-Csv
}

# Repeat for each replication found
foreach ($connection in ($replications | Select -Skip 1)) {

    # If there are no failuers
    if (($connection."Number of Failures" -eq 0) -and ($connection."Last Failure Time" -eq 0) -and ($connection."Last Failure Status" -eq 0)) {

        # Calculate time diff
        $nowTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $successTime = $connection."Last Success Time"
        $diffTime = New-TimeSpan -Start $successTime -End $nowTime

        # If the replication is done within the maxDiffTime
        if ($diffTime.TotalMinutes -le $maxDiffTime) {
            
            # Define Nagios return code
            $status = 0
        
        } else {

            # Define Nagios return code
            $status = 1
            $warnMessage += "Replication of $($connection."Naming Context") between $($connection."Source DSA") and $($connection."Destination DSA") was last sucessfull at $($successTime) ($([math]::Round($diffTime.TotalMinutes)) minutes ago) - "
        }
    
    # If there are any failures
    } else {

        # Define Nagios return code
        $status = 2
        $critMessage += "Replication of $($connection."Naming Context") between $($connection."Source DSA") and $($connection."Destination DSA") failed at $($connection."Last Failure Time") with the error $($connection."Last Failure Status") - "
    }
}

# Return to Nagios
if ($status -eq 0) {

    Write-Host "OK: All replications are working!"
    exit 0

} elseif ($status -eq 1) {

    Write-Host "Warning:" $warnMessage
    Remove-Variable -Name warnMessage
    exit 1

} elseif ($status -eq 2) {

    Write-Host "Critical:" $critMessage
    Remove-Variable -name critMessage
    exit 2

} else {

    Write-Host "UNKOWN: An unkown error has occured!"
    exit 3
}