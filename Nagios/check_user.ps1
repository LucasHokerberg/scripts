# -------------------------------------------------------------------------------------------------------------
# This script checks if a specific user is logged on to a specific system. The script will cath any error.
# Status is OK if the user is logged on, and CRITICAL if not.
#
# Usage:
# ./check_user.ps1 -ComputerName <Computer Name> -DomainName <Domain Name> -Username <Username>
#
# Arguments:
# ComputerName - The name of the computer to check
# DomainName - The domain short name the user is member of
# Username - The username of the user that must be logged on
#
# Examples:
# ./check_user.ps1 -ComputerName SERVER01 -DomainName DOM -Username BatchUser
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [string]$ComputerName,
    [string]$DomainName,
    [string]$Username
)

# Reset status
$NagiosStatus = "0"

# Try to find the user
try {

    # Make all errors terminating
    $ErrorActionPreference = "Stop";

    $LoggedOnUsers = Get-WMIObject Win32_Process -Filter 'name="explorer.exe"' -ComputerName $ComputerName |
    
    ForEach-Object {

        $owner = $_.GetOwner(); '{0}\{1}' -f $owner.Domain, $owner.User
    } |

    Sort-Object | Get-Unique
}

# Something went wrong
catch {

    $NagiosStatus = "3"

    if ($Error[0].Exception -match "0x800706BA") {

        Write-Host "Error: The target system is unreachable."

    } elseif ($Error[0].Exception -match "0x80070005") {

        Write-Host "Error: Access denied on $ComputerName"

    } else {

        Write-Host "Script execution failed. An error occurred."
    }

    # Return status
    exit $NagiosStatus
}

# Reset the error action preference to default
finally {

    $ErrorActionPreference = "Continue";
}

# No users are logged on at all
if ([string]::IsNullOrEmpty($LoggedOnUsers)) {

	$NagiosStatus = "2"
    Write-Host "No users are logged on to $ComputerName"

# The user is logged on
} elseif ($LoggedOnUsers -eq $DomainName + "\" + $Username) {

    $NagiosStatus = "0"
    Write-Host "User $Username is logged on to $ComputerName"

# The user is not logged on
} else {

    $NagiosStatus = "2"
    Write-Host "User $Username is NOT logged on to $ComputerName"
}

# Return status
exit $NagiosStatus