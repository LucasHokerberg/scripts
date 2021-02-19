This a set of tools to check if one or more Citrix sessions (desktop or app) are working and to mesure the logon time.
The check can be used to verify Citrix functionality as well as monitor the logon performance.

The check is divided into three parts:

	1) The start_citrix_session script which has to be scheduled to run by a logged in user on a fixed interval.
	   This is the logon robot.

	2) The log_citrix_session script which has to be autostarted within the robot's Citrix session.
	   The PowerShell script can be called from the autostart folder using the batch script.

	3) The check_citrix_logon script which is the NSClient script to be run by Nagios.
	   This script will parse the log file to determine if the last session was successfull and also the logon performance.

The check requires Citrix Workspace and storebrowse, which comes with Workspace.
Place the check_citrix_logon folder somewhere (e.g. under C:\Script) and edit the start script to your needs.
Place the log and run script in the Citrix session and edit them to your needs.
At last, place the check script in NSClient's custom script folder and edit it to your needs.

----------
Add the following to your nsclient.ini to enable the script:

[/settings/external scripts/scripts]
check_citrix_logon = cmd /c echo scripts\custom\check_citrix_logon.ps1 -LogFile "$ARG1$" -LastLogon $ARG2$ -Warning $ARG3$ -Critical $ARG4$; exit($lastexitcode) | powershell.exe -command -
----------

----------
Execute the following command in the scheduled task:

powershell -Command "& 'C:\Script\check_citrix_logon\start_citrix_session.ps1' -AppName 'My App 1','My App 2'"
----------