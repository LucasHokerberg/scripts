<#

This script parses the check_citrix_logon log file and calculates the logon time, and then reports the status back to Nagios.
The script requires that the start_citrix_session script has been run and that the session was successfull.

Usage: .\check_citrix_logon.ps1 -LogFile <Log file name> -LastLogon <Minutes since last logon> -Warning <Warning logon time in seconds> -Critical <Critical logon time in seconds>

Created: 2021-02-17
Author: lucas.hokerberg@gelita.com

#>

# Fetch parameters
param (
    [string] $LogFile,
    [int] $LastLogon,
    [int] $Warning,
    [int] $Critical
)

# Check if log file exists
if (Test-Path $LogFile) {

    # Check if log file is fresh
    $writeTime = [datetime](Get-ItemProperty -Path $LogFile -Name LastWriteTime).lastwritetime
    $writeTime = New-TimeSpan -Start $writeTime -End (Get-Date)
    
    if ($writeTime.TotalMinutes -gt $LastLogon) {

        Write-Host "Critical: Log file is too old ($($writeTime.TotalMinutes) minutes)!"
        exit 2
    
    } else {

        # Parse log file
        Get-Content $LogFile | Select-String "<start>(.+)</start>" | ForEach-Object {
    
            $startTime = $_.Matches[0].Groups[1].Value
            $startTime = [datetime]::parseexact($startTime, "yyyy-MM-dd HH:mm:ss", $null)
        }
        Get-Content $LogFile | Select-String "<end>(.+)</end>" | ForEach-Object {
    
            $endTime = $_.Matches[0].Groups[1].Value
            $endTime = [datetime]::parseexact($endTime, "yyyy-MM-dd HH:mm:ss", $null)
        }

        # Calculate logon time
        if (($startTime -is [System.ValueType]) -and ($endTime -is [System.ValueType])) {

            $logonTime = New-TimeSpan -Start $startTime -End $endTime

        } else {

            Write-Host "Critical: Unable to parse log file!"
            exit 2
        }

        # Check if logon time is applicable
        if ($logonTime.TotalSeconds -gt 0) {

            # If logon time is critical
            if ($logonTime.TotalSeconds -ge $Critical) {
                
                Write-Host "Critical: Session started in $($logonTime.TotalSeconds) seconds|Logontime=$($logonTime.TotalSeconds)"
                exit 2
     
             # If sessions is warning
             } elseif ($logonTime.TotalSeconds -ge $Warning) {
        
                Write-Host "Warning: Session started in $($logonTime.TotalSeconds) seconds|Logontime=$($logonTime.TotalSeconds)"
                exit 1
     
             # If sessions is OK
             } elseif ($logonTime.TotalSeconds -lt $Warning) {

                Write-Host "OK: Session started in $($logonTime.TotalSeconds) seconds|Logontime=$($logonTime.TotalSeconds)"
                exit 0
            }

        } else {

            Write-Host "Critical: Unable to calculate logon time!"
            exit 2
        }
    }

} else {

    Write-Host "Critical: Log file does not exists!"
    exit 2
}

# Something went wrong
Write-Host "Unknown: Something went wrong!"
exit 3