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
param([string] $cluster)

# Define variables
$notUp = ""

# Import modules
Import-Module FailoverClusters

# Repeat for all cluster nodes
Get-ClusterNode -cluster $cluster | Select Name,State | Select-Object Name,State | ForEach-Object {

    $name = $_.Name
    $state = $_.State
    
    # If node is not up
    if ($state -ne "Up") {

        # Add node to status
        $notUp = $notUp + "$($name) is $($state)! "
    }
}

# If a node is not up
if ($notUp -ne "") {

    Write-Host "CRITICAL: " + $notUp
    exit 2

# All nodes online
} else {

    Write-Host "OK: All nodes are up!"
    exit 0
}

# Unknown error
Write-Host "UNKOWN: An unkown error occured!"
exit 3
