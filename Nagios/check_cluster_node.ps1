# -------------------------------------------------------------------------------------------------------------
# Script to monitor Windows Failover Cluster node.
#
# Usage:
# ./check_cluster_node.ps1 -cluster <Cluster Name>
#
# Examples:
# ./check_cluster_node.ps1 -cluster FSCL01
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param(
    [string] $cluster
)

# Load modules
Import-Module FailoverClusters

# Get status of all cluster nodes
Get-ClusterNode -Cluster $cluster | Select Name,State | Sort-Object State -Descending | Select-Object Name,State | ForEach-Object {

    $name = $_.Name
    $state = $_.State

    # Node Down
    if ($state -eq "Down") {

        Write-Host "$name is $state" 
        exit 2

    # Node Paused
    } elseif ($state -eq "Paused") {

        Write-Host "$name is $state"
        exit 1

    # All nodes Online
    } else {

        Write-Host "All nodes are online!"
        exit 0
    }
}

exit 2