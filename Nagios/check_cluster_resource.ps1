# -------------------------------------------------------------------------------------------------------------
# Script to monitor Windows Failover Cluster resource.
#
# Usage:
# ./check_cluster_resource.ps1 -cluster <Cluster Name>
#
# Examples:
# ./check_cluster_resource.ps1 -cluster FSCL01
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param([string] $cluster)

# Define variables
$notOnline = ""

# Import modules
Import-Module FailoverClusters

# Repeat for all resources
Get-ClusterResource -cluster $cluster | Select Name,State | Select-Object Name,State | ForEach-Object {

    $name = $_.Name
    $state = $_.State

    # If resource is not online
    if ($state -ne "Online") {

        # Add resource to status
        $notOnline = $notOnline + "$($name) is $($state)! "
    }
}

# If a resource is not online
if ($notOnline -ne "") {

    Write-Host "CRITICAL: $($notOnline)"
    exit 2

# All nodes online
} else {

    Write-Host "OK: All resources are online!"
    exit 0
}

# Unknown error
Write-Host "UNKOWN: An unkown error occured!"
exit 3
