<#

This script goes through each process with a given name and cheks if the process has a corresponing TCP connection.
If no TCP connection is found, the script will retry for a given ammount of seconds (if given).
If there's still no connection, the script will kill the process.

Created: 2023-04-27
Author: lucas.hokerberg@gelita.com

Usage:
.\Kill-ProcessWoConnection.ps1 -ProcessName <Process Name> -Retry <Seconds> -Exclude <Comma separated list of processes>

Parameters:
ProcessName: The name of the process to check (supports wildcard)
Retry (optional): How many seconds to re-check for a connection before terminating the process
Exclude (optinal): A single process or a comma separated list of processes to exclude from the check

Example:
.\Kill-ProcessWoConnection.ps1 -ProcessName edge.exe
.\Kill-ProcessWoConnection.ps1 -ProcessName explorer -Retry 10
.\Kill-ProcessWoConnection.ps1 -ProcessName process*
.\Kill-ProcessWoConnection.ps1 -ProcessName process* -Exclude process5 

#>

# Fetch parameters
param (
    [string] $ProcessName,
    [int] $Retry = 0,
    [array] $Exclude = $null
)

# Define log settings
$logFolder = "C:\Scripts" # Name of log folder
$logFile = "Kill-ProcessWoConnection" # Name of log file (without file extension)
$logKeep = 7 # Days to keep logs for

# Clean up old log files
Get-ChildItem "$($logFolder)\$($logFile)*.log" | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-$logKeep))} | Remove-Item

# Keep track of number of processes
$pn = 0
$kn = 0

# For each process running
ForEach ($process in Get-Process -Name $ProcessName) {

    $pn++

    # Reset result
    $result = $false

    # Abort if process is excluded
    if (($Exclude -ne $null) -and ($Exclude.Contains($process.ProcessName))) {

        "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - [$($pn)] Process $($process.ProcessName) is excluded! Skipping..." >>`
        "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"

        continue
    }

    # Try to find corresponding TCP connection
    if ($connection = Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue) {

        # Connection found - take no further action
        $result = $true

        "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - [$($pn)] Process $($process.ProcessName) (PID $($process.Id)) is in state $($connection.State) on port $($connection.LocalPort)" >>`
        "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"
    
    # No connection found
    } else {

        # Retry if specified
        $rn = 1

        while (($Retry -gt 0) -and ($rn -le $retry)) {

            "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - [$($pn)] Process $($process.ProcessName) (PID $($process.Id)) has no TCP connection! Retrying... ($($rn) of $($Retry) retries)"`
            >> "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"
             
            # Try to find connection
            if ($connection = Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue) {

                # Connection found - abort
                $result = $true

                "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - [$($pn)] Process $($process.ProcessName) (PID $($process.Id)) is in state $($connection.State) on port $($connection.LocalPort)"`
                >> "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"

                break
            
            # No connection found - keep retrying
            } else {

                Start-Sleep 1
            }

            $rn++
        }
    }

    # No connection was found - kill process
    if ($result -ne $true) {

        "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - [$($pn)] Process $($process.ProcessName) (PID $($process.Id)) has no TCP connection! Killing process..."`
        >> "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"

        Stop-Process -Id $process.Id -Force
        $kn++
    }
}

# Script done
"$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - DONE: $($kn) of $($pn) processes killed!`n"`
>> "$($logFolder)\$($logFile)_$(Get-Date -Format "yyyy-MM-dd").log"