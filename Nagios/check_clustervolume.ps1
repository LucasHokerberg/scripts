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
param(
    [string] $cluster
)

# Load modules
Import-Module FailoverClusters

# Get status of all cluster volumes
Get-Clustersharedvolume -cluster $cluster | Select Name,State,Node | Sort-Object State -Descending | Select-Object Name,State,Node | ForEach-Object {

    $name = $_.Name
    $state = $_.State
    $node = $_.Node
    $exitcrit = 0

    # Volume not Online
    if ($state -ne "Online") {

        Write-Host "$name is $state on node $node" 
        exit 2

    # All volumes Online
    } else {

        Write-Host "All shared volume are online!"
        exit 0
    }
}

exit 2