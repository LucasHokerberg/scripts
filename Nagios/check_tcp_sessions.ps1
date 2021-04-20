<#

This script is used to count the number of sessions on a given port or port range with a given state.
If given, the script will alert if the number of sessions is above the given threshold.

Author: lucas@hokerberg.com

Usage:
.\check_tcp_sessions.ps1 -Port <Port number> -Range <From port,To port> -State <State> -Warning <Warning threshold> -Critical <Critical threshold>

Example:
.\check_tcp_sessions.ps1 -Port 1101 -State Listen
.\check_tcp_sessions.ps1 -Range 1101,1200 -Warning 90 -Critical 95

#>

# Fetch parameters
param (
    [int]$Port = 0,
    [array]$Range = 0,
    [string]$State = "Established",
    [int]$Warning = 0,
    [int]$Critical = 0
)

# If a single port is specified
if ($Port -gt 0) {

    # Count sessions
    $n = @(Get-NetTCPConnection -State $State -LocalPort $Port -ErrorAction SilentlyContinue)
    $n = $n.count

# If a range is specified
} elseif ($Range -ne 0) {

    # Count sessions
    $n = @(Get-NetTCPConnection -State $State | Where-Object { (($_.LocalPort -ge $Range[0]) -and ($_.LocalPort -le $Range[1])) })
    $n = $n.count

# If no port is specified
} else {

    Write-Host "Unknown: No port or port range is specified!"
    Exit 3
}

# Critical
if (($Critical -gt 0) -and ($n -ge $Critical)) {

    Write-Host "Critical: $($n) sessions found!|Sessions=$($n);$Warning;$Critical;0"
    Exit 2

# Warning
} elseif (($Warning -gt 0) -and ($n -ge $Warning)) {

    Write-Host "Warning: $($n) sessions found!|Sessions=$($n);$Warning;$Critical;"
    Exit 1

# OK
} else {

    Write-Host "OK: $($n) sessions found|Sessions=$($n);$Warning;$Critical;"
    Exit 0
}

# Something went wrong
Write-Host "Unknown: Something went wrong!"
Exit 3
