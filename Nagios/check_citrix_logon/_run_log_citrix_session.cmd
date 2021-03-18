@echo off

rem This script runs the log_citrix_session PowerShell script.
rem Call this script at logon.

rem Created: 2021-03-05
rem Author: lucas@hokerberg.com

powershell.exe -File "%UserProfile%\Desktop\log_citrix_session.ps1"

exit
