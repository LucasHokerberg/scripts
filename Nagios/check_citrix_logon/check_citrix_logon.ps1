<#

This script starts a Citrix session with the help of storebrowse.
In the Citrix session, the log_citrix_session script must be run to log the logon time and end the session.
The script will then calculate the logon performance and report the state to Nagios with the help of send_nsca.

Usage: .\check_citrix_logon.ps1 -AppName <Name of application or desktop> -Warning <Logon time in s for warning> -Critical <Logon time in s for critical>
Example: .\check_citrix_logon.ps1 -AppName "My App 1" -Warning 60 -Critical 90

Created: 2021-03-05
Author: lucas@hokerberg.com

#>

# Fetch parameters
param (
    [string] $AppName,
    [int] $Warning = 60,
    [int] $Critical = 90
)

# Define static paremeters
$userLogin = "robot"
$userPassword = "secretpassword"
$userDomain = "domain.ltd"
$storeUrl = "https://citrix.domain.ltd/Citrix/Store/discovery"

$nscaPath = "C:\Robot\send_nsca"
$nscaHost = "nagios.domain.ltd"
$nscaPort = "5667"

# Start performance tracking
Remove-Item "$($AppName).log" -ErrorAction SilentlyContinue
New-Item "$($AppName).log"

$startTime = Get-Date

# Launch new Citrix session
Start-Process -FilePath "C:\Program Files (x86)\Citrix\ICA Client\AuthManager\storebrowse.exe" -ArgumentList @("-U $($userLogin)", "-P $($userPassword)", "-D $($userDomain)", "-S `"$($AppName)`"", $storeUrl)

# Wait for session to log
$retry = 0
$maxRetry = ($Critical+10)/10

while ((Get-Content -Path "$($AppName).log") -eq $null) {
    
    $retry++

    if ($retry -lt $maxRetry) {
        
        Write-Host "Waiting for session to log (retry $($retry) of $($maxRetry))..."
        Start-Sleep -Seconds 10
    
    } else {

        # Timeout - Send result to Nagios
        $output = "$($env:computername);$($AppName);2;Critical: Citrix session taking too long time to log!"
        $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
        exit 2
    }
}

# Allow session to complete logging
Start-Sleep -Seconds 1

# Calculate logon time
$endTime = Get-Content -Path "$($AppName).log" -ErrorAction SilentlyContinue
$endTime = [datetime]::parseexact($endTime, "yyyy-MM-dd HH:mm:ss", $null)

if (($startTime -is [System.ValueType]) -and ($endTime -is [System.ValueType])) {

    $logonTime = New-TimeSpan -Start $startTime -End $endTime
    $logonTime = $([math]::Round($logonTime.TotalSeconds))

} else {

    # Calculation failed - Send result to Nagios
    $output = "$($env:computername);$($AppName);2;Critical: Unable to calculate logon time!"
    $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
    exit 2
}

if ($logonTime -gt 0) {

    # Logon time is critical
    if ($logonTime -ge $Critical) {

        # Send result to Nagios
        $output = "$($env:computername);$($AppName);2;Critical: Logon time $($logonTime) seconds|Logontime=$($logonTime)"
        $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
        exit 2
     
    # Logon time is warning
    } elseif ($logonTime -ge $Warning) {

        $output = "$($env:computername);$($AppName);1;Warning: Logon time $($logonTime) seconds|Logontime=$($logonTime)"
        $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
        exit 1
     
    # Logon time is OK
    } elseif ($logonTime -lt $Warning) {

        $output = "$($env:computername);$($AppName);0;OK: Logon time in $($logonTime) seconds|Logontime=$($logonTime)"
        $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
        exit 0
    }

} else {

    # Calculation failed - Send result to Nagios
    $output = "$($env:computername);$($AppName);2;Critical: Unable to calculate logon time!"
    $output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
    exit 2
}

# Something went wrong
$output = "$($env:computername);$($AppName);3;Unknown: Something went wrong!"
$output | & "$($nscaPath)\send_nsca.exe" -H $nscaHost -p $nscaPort -c "$($nscaPath)\send_nsca.cfg" -d ";"
exit 3
