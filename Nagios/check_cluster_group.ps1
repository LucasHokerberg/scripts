<#

Script to monitor Windows Failover Cluster groups. Will check all grouped resources in a cluster and return;

    a) CRITICAL if any group with a priority higher than 0 (i.e. with autostart) is not online.
    b) WARNING if any group is not at it's prefered owner (if -Owner specified)

"Available Storage" group will be ignored by default, but can be checked by adding -Storage $true.

Usage:
./check_cluster_group.ps1 -Cluster <Cluster Name> -Storage <$true / $false (default)> -Owner <Preferred owner>

Examples:
./check_cluster_group.ps1 -Cluster "SQLCL01"
./check_cluster_group.ps1 -Cluster "FSCL01" -Storage $true
./check_cluster_group.ps1 -Cluster "FSCL01" -Storage $true -Owner "FS01"
./check_cluster_group.ps1 -Cluster "APPCL01" -Owner "APP02"

Author: lucas@hokerberg.com

#>

# Fetch parameters
param(
    [string] $Cluster,
    [boolean] $Storage = $false,
    [string] $Owner
)

# Define variables
$notOnline = ""
$badOwner = ""

# Import modules
Import-Module FailoverClusters

# Repeat for all resources
Get-ClusterGroup -Cluster $Cluster | Select Name,State,OwnerNode,Priority | Select-Object Name,State,OwnerNode,Priority | ForEach-Object {

    $name = $_.Name
    $state = $_.State
    $ownerNode = $_.OwnerNode
    $priority = $_.Priority

    # Skip Available Storage if not requested
    if (($name -eq "Available Storage") -and ($Storage -eq $false)) {
    
        return
    }

    # If group is not online but should be
    if (($state -ne "Online") -and ($priority -gt 0)) {

        # Add group to status
        $notOnline = $notOnline + "$($name) is $($state)! "
    }

    # If preferred owner is specified and group is owned by wrong host
    if (($Owner -ne "") -and ($Owner -ne $ownerNode)) {

        # Add group to status
        $badOwner = $badOwner + "$($name) is owned by $($ownerNode)! "
    }
}

# If a group is not online
if ($notOnline -ne "") {

    Write-Host "CRITICAL: $($notOnline) $($badOwner)"
    exit 2

# If a group has bad owner
} elseif ($badOwner -ne "") {

    Write-Host "WARNING: $($badOwner)"
    exit 1

# All groups OK
} else {

    Write-Host "OK: All groups are OK!"
    exit 0
}

# Unknown error
Write-Host "UNKOWN: An unkown error occured!"
exit 3