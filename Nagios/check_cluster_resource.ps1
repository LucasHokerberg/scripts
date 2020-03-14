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

# Get status of all cluster resources
Get-ClusterResource -cluster $cluster | Select Name,State | Sort-Object State -Descending | Select-Object Name,State | ForEach-Object {

    $name = $_.Name
    $state = $_.State

    # Resource not online
    if ($state -ne "Online") {

        Write-Host "$name is $state" 
        exit 2

    # All resources Online
    } else {

        Write-Host "All resources are online!"
        exit 0
    }
}

exit 2