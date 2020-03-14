# -------------------------------------------------------------------------------------------------------------
# Script to reset a local users password (for instance change the local Administrator password).
#
# Created: 2019-07-09
# Author: lucas.hokerberg@gelita.com
#
# Usage:
# 1) Enter all servers where you want to update the password in servers.txt.
# 2) Run this script and enter the following information when promted:
#    * Username and password for an account with admin privileges on the servers (e.g. a Domain Admin)
#    * Username for the account whose password is to be changed followed by the new password itself
# -------------------------------------------------------------------------------------------------------------

# Get all servers from list
$servers = Get-Content .\servers.txt

# Ask for admin username and password
$adminCred = Get-Credential

# Ask for username and new password
$newCred = Get-Credential

# Repeat for each server in server list
foreach ($server in $servers) {

    # Update password with pspasswd.exe
    .\pspasswd.exe -accepteula \\$server -u $adminCred.GetNetworkCredential().Username -p $adminCred.GetNetworkCredential().Password $newCred.GetNetworkCredential().Username $newCred.GetNetworkCredential().Password
}