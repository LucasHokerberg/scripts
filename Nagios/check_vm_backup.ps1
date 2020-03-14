# -------------------------------------------------------------------------------------------------------------
# This script checks if a backup has been taken on a VM in vSphere by looking at a custom attribute set by Veeam.
# The script parses the time stamp and checks if the backup is taken within the desired time frame.
#
# Usage:
# .\check_vm_backup.ps1 -vmName <VM name> -lastBackup <Time in minutes> -exclude <VM name> -username <Username to vCenter> -password <Password to vCenter>
#
# Arguments:
# vmName - The name of a VM to check. Can be several VMs separated by comma. Enter * to check all VMs.
# lastBackup - Number of minutes when the latest backup must be taken.
# exclude - The name (or part of) of a VM to exclude from the check. Can be several VMs seperated by comma. Only applicable if vmName is set to *.
# username - The username for a user with at least read-permissions in vCenter.
# password - The password for the above user.
#
# Examples:
# .\check_vm_backup.ps1 -vmName 'DC01','DC02','APP01' -lastBackup 60 -username 'nagios' -password 'P4$$w0rd'
# .\check_vm_backup.ps1 -vmName * -lastBackup 1440 -exclude 'DC', 'FS01','FS02' -username 'nagios' -password 'P4$$w0rd'
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Define parameters
param (
    [array]$vmName,
    [int]$lastBackup,
    [array]$exclude,
    [string]$username,
    [string]$password
)

# Define static variables
$vcServer = "vcenter.domain.local"

# Disable CEIP and certificate warning
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $username -Password $password | Out-Null

# If all VMs are to be checked
if ($vmName -eq "*") {

    # Convert exclude array to regex
    $exclude = $exclude -Join '|'
    
    # Loop for each VM in vSphere
    foreach ($vmInfo in Get-VM | Where-Object -FilterScript {( $_.Name -NotMatch $exclude )}) {

        # If the VM is not listed in exclude
        if ($exclude -NotContains $vmInfo) {
        
            # Parse out the backup time from Veeam custom attribute
            $backupTime = $vmInfo.CustomFields | Select-String -Pattern "Veeam Backup:.*Time:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}

            # If the backup time is missing
            if (!$backupTime) {

                $missing = "$missing '$vmInfo'"
            
            # If a backup time is set
            } else {

                # Convert backupTime to date
                $backupTime = [datetime]::parseexact($backupTime, "yyyy-MM-dd HH:mm:ss", $null)

                # If the backup is too old
                $minTime = (Get-Date).AddMinutes(-$lastBackup)
                if ($backupTime -lt $minTime) {

                    $old = "$old '$vmInfo' ($backupTime)"
                
                # If the backup is OK
                } elseif ($backupTime -gt $minTime) {
                    
                    # Keep in count how many VMs are backed up
                    $n = $n + 1
                }
            }

            # Unset $backupTime
            Remove-Variable -name backupTime
        }
    }

# If specific VMs are to be checked
} else {

    # Loop for each VM in vSphere
    foreach ($vm in $vmName) {
        
        # Get VM info
        $vmInfo = Get-VM -Name $vm

        # Parse out the backup time from Veeam custom attribute
        $backupTime = $vmInfo.CustomFields | Select-String -Pattern "Veeam Backup:.*Time:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}
        
        # If the backup time is missing
        if (!$backupTime) {

            $missing = "$missing '$vmInfo'"
            
        # If a backup time is set
        } else {

            # Convert backupTime to date
            $backupTime = [datetime]::parseexact($backupTime, "yyyy-MM-dd HH:mm:ss", $null)

            # If the backup is too old
            $minTime = (Get-Date).AddMinutes(-$lastBackup)
            if ($backupTime -lt $minTime) {

                $old = "$old '$vmInfo' ($backupTime)"
                
            # If the backup is OK
            } elseif ($backupTime -gt $minTime) {
                    
                # Keep in count how many VMs are backed up
                $n = $n + 1
            }
        }

        # Unset $backupTime
        Remove-Variable -name backupTime
    }
}

# Disconnect from vCenter
Disconnect-VIServer $vcServer -Confirm:$false

# If VMs are without backup
if ($missing) {

    Write-Host "Critical: The following servers are not beeing backed up:$missing!"
    exit 2

# If VMs have old backups
} elseif ($old) {

    Write-Host "Critical: The following servers have old backups:$old!"
    exit 2

# If all VMs are backed up
} elseif ($n -ge 1) {

    Write-Host "OK: $n servers have valid backups!"
    exit 0

# Something went wrong
} else {

    Write-Host "UNKOWN: An unkown error occured!"
    exit 3
}

Write-Host "UNKOWN: An unkown error occured!"
exit 3