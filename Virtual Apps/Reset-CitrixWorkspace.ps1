# ---------------------------------------------------------------------------------
# This script resets both Citrix Workspace and shortcuts created by the client.
#
# Author: lucas.hokerberg@gelita.com
# Created: 2020-04-02
#
# Usage: .\Reset-CitrixWorkspace.ps1
# ---------------------------------------------------------------------------------

# Define static variables
$shortcutFolder = "$($env:APPDATA)\Microsoft\Windows\Start Menu\Programs\Citrix"

# Abort if Workspace is not installed
if (!(Test-Path "C:\Program Files (x86)\Citrix\ICA Client\Receiver\Receiver.exe")) {

    Exit 0
}

# Wait for Workspace to start
while ((Get-Process -Name "Receiver" -ErrorAction SilentlyContinue).Count -eq 0) {
    
    Start-Sleep 5
}

# Clean-up Workspace
Start-Process "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\CleanUp.exe" -ArgumentList "/silent -cleanUser"

# Remove shortcut folder
Remove-Item -Path $shortcutFolder -Recurse -Force -ErrorAction SilentlyContinue

# Wait for shortcut folder to come back
while (!(Test-Path $shortcutFolder)) {

    Start-Sleep 5
}

# Poll for new shortcuts
Start-Sleep 5; Start-Process "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe" -ArgumentList "-poll"
Exit 0
