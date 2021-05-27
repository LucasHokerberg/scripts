<#

This script can be used to run a batch file remotley on a list of computers.
It will copy a batch file to the remote computer, then use PsExec to start CMD and run the batch file.
The batch file is then removed from the remote target once done.

The script will use C:\Temp on the remoce computer as a working folder.
If the folder does not exists, it will be created.

Created: 2021-05-27
Author: lucas@hokerberg.com

#>

# Define static variables
$computerList = Get-Content "computers.txt"
$batchFile = "myscript.cmd"

# For each computer in the computer list
foreach ($computer in $computerList) {

    # Remote computer online
    if (Test-Connection -ComputerName $computer -Quiet) {

        # Copy batch file
        Write-Host "-----------------------------------------"
        Write-Host "Copying batch file to $($computer)..."
        New-Item -Path "\\$computer\C$\" -Name "Temp" -ItemType "directory" -ErrorAction SilentlyContinue
        Copy-Item $batchFile "\\$($computer)\C$\Temp"
        
        # Run batch file
        Write-Host "Running batch file on $($computer)..."
        & ".\PsExec.exe" @("\\$($computer)", "-s", "-i", "cmd", "/c C:\Temp\$($batchFile)")

        # Remove batch file
        Write-Host "Removing script from $($computer)..."
        Remove-Item "\\$($computer)\C$\Temp\$($batchFile)"

    # Remote computer offline
    } else {

        Write-Host "$($computer) is offline. Skipping..."
    }
}