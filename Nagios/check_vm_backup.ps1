<#

This script checks if a backup has been taken on a VM in vSphere by looking at a custom attribute set by Veeam.
The script parses the time stamp and checks if the backup is taken within the desired time frame.

Usage:
.\check_vm_backup.ps1 -VMName <Name> -Exclude <Name> -LastBackup <Minutes> -Attribute <Name> -Server <Name/IP> -Username <Username> -Password <Password>

Arguments:
VMName - The name of a VM to check. Can be several VMs separated by comma. Enter * to check all VMs.
Exclude - The name (or part of) of a VM to exclude from the check. Can be several VMs seperated by comma. Only applicable if VMName is set to *.
LastBackup - Number of minutes since the latest backup must be taken.
Attribute - name of the attribute used by Veeam. Could be a custom named attribute or the default Notes attribute.
Server - DNS name or IP address to the vCenter server or ESXi host.
Username - The username for a user with at least read-permissions on the server.
Password - The password for the above user.

Examples:
.\check_vm_backup.ps1 -VMName DC01,DC02,APP01 -LastBackup 60 -Attribute 'Veeam Backup' -Server vc01.domain.local -Username nagios -Password P4$$w0rd
.\check_vm_backup.ps1 -VMName * -Exclude DC,FS01,FS02 -LastBackup 1440 -Attribute Notes -Server 192.168.100.10 -Username nagios -Password P4$$w0rd

Author: lucas@hokerberg.com

#>

# Define parameters
param (
    [array]$VMName,
    [array]$Exclude,
    [int]$LastBackup,
    [string]$Attribute,
    [string]$Server,
    [string]$Username,
    [string]$Password
)

# Disable CEIP and certificate warning
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vSphere
Connect-VIServer -Server $Server -User $Username -Password $Password | Out-Null

# If all VMs are to be checked
if ($VMName -eq "*") {

    # Convert exclude array to regex
    $Exclude = $Exclude -Join "|"
    
    # Loop for each VM in vSphere
    foreach ($vmInfo in Get-VM | Where-Object -FilterScript {( $_.Name -notmatch $Exclude )}) {
        
        # Attribute is Notes
        if ($Attribute -eq "Notes") {

            # Extract backup time from notes
            $backupTime = $vmInfo.Notes | Select-String -Pattern "Last backup:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}
            
        # Attribute is not Notes (i.e. custom attribute)
        } else {

            # Extract backup time from custom attribute
            $backupTime = $vmInfo.CustomFields | Where-Object -FilterScript {( $_.Key -eq $Attribute)}
            $backupTime = $backupTime.Value | Select-String -Pattern "Last backup:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}
        }

        # If backup time is missing
        if (!$backupTime) {

            $missing = "$($missing) '$($vmInfo.Name)'"
            
        # If a backup time is set
        } else {

            # Convert backupTime to date
            $backupTime = [datetime]::parseexact($backupTime, "yyyy-MM-dd HH:mm:ss", $null)

            # If backup is too old
            $minTime = (Get-Date).AddMinutes(-$LastBackup)
            if ($backupTime -lt $minTime) {

                $old = "$($old) '$($vmInfo.Name)' ($($backupTime))"
                
            # If backup is OK
            } elseif ($backupTime -gt $minTime) {
                    
                # Keep in count how many VMs are OK
                $n = $n + 1
            }
        }

        Remove-Variable -Name backupTime
    }

# If specific VMs are to be checked
} else {

    # Loop for each VM in vSphere
    foreach ($vm in $vmName) {
        
        # Get VM info
        $vmInfo = Get-VM -Name $vm

        # Attribute is Notes
        if ($Attribute -eq "Notes") {

            # Extract backup time from notes
            $backupTime = $vmInfo.Notes | Select-String -Pattern "Last backup:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}
            
        # Attribute is not Notes (i.e. custom attribute)
        } else {

            # Extract backup time from custom attribute
            $backupTime = $vmInfo.CustomFields | Where-Object -FilterScript {( $_.Key -eq $Attribute)}
            $backupTime = $backupTime.Value | Select-String -Pattern "Last backup:.*\[([0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*)]" | % {$($_.matches.groups[1])}
        }
        
        # If backup time is missing
        if (!$backupTime) {

            $missing = "$($missing) '$($vmInfo.Name)'"
            
        # If a backup time is set
        } else {

            # Convert backupTime to date
            $backupTime = [datetime]::parseexact($backupTime, "yyyy-MM-dd HH:mm:ss", $null)

            # If backup is too old
            $minTime = (Get-Date).AddMinutes(-$lastBackup)
            if ($backupTime -lt $minTime) {

                $old = "$($old) '$($vmInfo.Name)' ($($backupTime))"
                
            # If backup is OK
            } elseif ($backupTime -gt $minTime) {
                    
                # Keep in count how many VMs are OK
                $n = $n + 1
            }
        }

        Remove-Variable -Name backupTime
    }
}

# Disconnect from vSphere
Disconnect-VIServer $Server -Confirm:$false

# If VMs are without backup
if ($missing) {

    Write-Host "Critical: The following servers are not beeing backed up:$missing!"
    exit 2

# If VMs have old backups
} elseif ($old) {

    Write-Host "Critical: The following servers have old backups:$old!"
    exit 2

# If all VMs are OK
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
