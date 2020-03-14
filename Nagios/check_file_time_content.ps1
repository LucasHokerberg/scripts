# -------------------------------------------------------------------------------------------------------------
# Script to monitor last modify time and (if required) content of a file.
# Can be used to alert if a specific content exists or not exists.
#
# Usage:
# ./check_file_time_content.ps1 -File <Path> -Mins <Minutes> -Content <String> -Exists <True/False>
#
# Arguments:
# File - Full path to the file to check
# Mins - Time in minutes required since last edit
# Content - Content (string) in file to look after
# Exists - If the content should exist in the file or not. True to exist and false to not exist.
#
# Examples:
# ./check_file_time_content.ps1 -File "C:\Logs\mylogfile.txt" -Mins 10 -Content "My function is working!" -Exists True
# ./check_file_time_content.ps1 -File "C:\Logs\mylogfile.txt" -Mins 60 -Content "error" -Exists False
# ./check_file_time_content.ps1 -File "C:\Logs\mylogfile.txt" -Mins 15
#
# Author: lucas@hokerberg.com
# -------------------------------------------------------------------------------------------------------------

# Fetch parameters
param (
    [string] $File,
    [int] $Mins,
    [string] $Content,
    [string] $Exists
)

# If file does not exists
if(![System.IO.File]::Exists($File)){
    
    # Return output
    Write-Host "Critical: $File does not exists!"
    exit 2

# Else continue
} else {

    # If file is not modified within the time limit
    $minTime = (Get-Date).AddMinutes(-$Mins)
    if ((Get-Item $file).LastWriteTime -lt $minTime) {
    
        # Return output
        Write-Host "Critical: $File has not been modified within the last $Mins minutes!"
        exit 2
    
    # Else continue
    } else {

        # If the content should be checked
        if ($Content) {

            $match = Select-String -Path $File -Pattern $Content

            # If the content provided should exists
            if ($Exists -eq "True") {

                # If the content does not exists
                if ($match -eq $null) {

                    # Return output
                    Write-Host "Critical: $Content does not exists in $File!"
                    exit 2
                }

            # If the content provided should not exists
            } elseif ($Exists -eq "False") {

                # If the content exists
                if ($match -ne $null) {

                    # Return output
                    Write-Host "Critical: $Content exists in $File!"
                    exit 2
                }
            
            # If Exists parameter is not True or False
            } else {
                
                # Return output
                Write-Host "UNKNOWN: Content parameter is set, but Exists parameter is not set to True or False!"
                exit 3
            }
        }

        # File is modified within the time limit - return output
        Write-Host "OK: File is OK!"
        exit 0
    }
}

Write-Host "UNKOWN: An unkown error has occured!"
exit 3