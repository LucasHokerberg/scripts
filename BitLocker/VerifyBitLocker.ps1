# -------------------------------------------------------------------------------------------------------------
# This script checks the BitLocker status on all computers in a given OU.
#
# Usage
# 1. Change the OU below
# 2. Run VerifyBitLocker.ps1 on a server with ADUC
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Import modules
Import-Module ActiveDirectory

# Get all computers in selected OU
$computers = Get-ADComputer -filter * -SearchBase "OU=Computers,DC=domain,DC=local"| ForEach-Object {$_.Name}

# Loop for each computer
ForEach ($computer in $computers) {
    
    # Get BitLocker status
    Manage-bde -ComputerName $computer -status
}