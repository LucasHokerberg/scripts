# -------------------------------------------------------------------------------------------------------------
# This script checks and activates BIOS password (on Dell computers only), TPM and BitLocker.
#
# You must have GPOs for BitLocker in place prior to running this script!
# You need to specify the use of TPM, where to save the key etc.
#
# Usage
# 1. Change the path below
# 2. Open Dell\BiosSettings.ini and change BIOS password
# 3. Run BitLockerMagic.ps1 as admin on computers where to activate BitLocker
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Script root path
$path = "\\fileserver\BitLockerMagic"

# Change directory to script root path
Set-Location $path

# Get information about the computer
$computer = Get-WmiObject Win32_Computersystem

# Get all information about TPM
$tpm = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm

# If the computer is a Dell
if ($computer.Manufacturer -match 'Dell') {
    
    # Debug
    Write-Host "Manufacurer is Dell"
    
    # Set a BIOS password
    $escape = "--%"
    & ".\Dell\cctk.exe" $escape "--infile=$path\Dell\BiosPassword.ini"

    # If TPM is NOT activated
    if ($tpm.IsActivated_InitialValue -eq $false) {
        
        # Debug
        Write-Host "TPM is NOT activated"

        # Activate TPM in BIOS
        $escape = "--%"
        & ".\Dell\cctk.exe" $escape  "--tpm=on tpmactivation=activate"
        Write-Host "TPM has been activated - Rebooting computer"

        # Return error code reboot computer
        shutdown -r -t 10 -f
        exit 1
    }
}

# If TPM is already activated
if ($tpm.IsActivated_InitialValue -eq $true) {
    
    # Debug
    Write-Host "TPM is activated"
    
    # Get status for BitLocker
    $bitlocker = (Manage-bde -status C: | where {$_ -match 'Conversion Status'})
    $bitlocker = $bitlocker.Split(":")[1].trim()

    # If BitLocker is NOT activated
    if ($bitlocker -notmatch 'Fully Encrypted') {
        
        # Debug
        Write-Host "BitLocker is NOT activated"
        
        # Enable BitLocker
        Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
        Manage-bde -on C: -EncryptionMethod AES256 -SkipHardwareTest
        Write-Host "BitLocker has been activated"

        # Return success code and reboot computer
        shutdown -r -t 10 -f
        exit 0
    }

    # If BitLocker is activated
    if ($bitlocker -match 'Fully Encrypted') {
        
        # Debug
        Write-Host "BitLocker is activated"
        
        # Return success code
        exit 0
    }
}

# Return error code
exit 1