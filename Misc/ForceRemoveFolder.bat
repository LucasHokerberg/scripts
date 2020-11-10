REM This script will force remove a folder by first taking ownership.
REM Created: 2015-03-13
REM Author: lucas@hokerberg.com

@echo off

:start

echo.
set /p pth=Set path to folder:

echo.
echo Taking ownership of the folder...
takeown /f %pth% /r /d y
icacls %pth% /grant %username%:F /t /q

echo.
echo Removing the folder...
rd /s /q %pth%

echo.
echo All done!

pause

cls
goto start
