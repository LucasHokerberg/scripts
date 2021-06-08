<#

Script to monitor failover mode in SQL AG groups.

Usage:
./check_ag_failover.ps1 -Instance <Instance name if any>

Examples:
./check_cluster_node.ps1 -Instance MSSQL
./check_cluster_node.ps1

Author: lucas@hokerberg.com
Created: 2021-06-08

#>

# Fetch parameters
param([string] $Instance)

# Define variables
$critical = 0
$output = ""

# Define server and instance
if ($Instance -ne "") {

    $server = [System.Net.Dns]::GetHostName() + "\" + $Instance

} else {

    $server = [System.Net.Dns]::GetHostName()
}

# Construct SQL query
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$($server);Database=master;Integrated Security=True"
$query = New-Object System.Data.SqlClient.SqlCommand
$query.CommandText = $("WITH AGStatus AS(SELECT	name as [AGName], replica_server_name AS [Server], failover_mode_desc AS [FailoverMode] FROM master.sys.availability_groups Groups INNER JOIN master.sys.availability_replicas Replicas ON Groups.group_id = Replicas.group_id INNER JOIN master.sys.dm_hadr_availability_group_states States ON Groups.group_id = States.group_id) SELECT [AGName], [Server], [FailoverMode] FROM AGStatus")
$query.Connection = $connection
$sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$sqlAdapter.SelectCommand = $query

# Connect to SQL and run query
$dataSet = New-Object System.Data.DataSet
$sqlAdapter.Fill($dataSet) | Out-Null
$connection.Close()
$data = $dataSet.Tables[0]

# Repeat for each AG group
foreach ($d in $data) {

    # If failover mode is not automatic
    if ($d.FailoverMode -ne "AUTOMATIC") {

        $critical++
        $output = $output + "$($d.AGName) on $($d.Server) is set to $($d.FailoverMode)! "

    # If failover mode is automatic
    } else {

        $output = $output + "$($d.AGName) on $($d.Server) is set to $($d.FailoverMode). "
    }
}

# Return output
if (($critical -eq 0) -and ($output -ne "")) {

    Write-Host "OK: $($output)"
    exit 0

} elseif (($critical -gt 0) -and ($output -ne "")) {

    Write-Host "Critical: $($output)"
    exit 2
}

# Something went wrong
Write-Host "Unknown: Something went wrong!"
exit 3
