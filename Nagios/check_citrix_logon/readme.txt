This a set of tools to check if a Citrix sessions (desktop or app) is working and to mesure the logon time.
The check can be used to verify Citrix functionality as well as monitor the logon performance.

The check is divided into two parts:

	1) The check_citrix_logon script which has to be scheduled to run by a logged in user on a fixed interval.
	   This is the logon robot.

	2) The log_citrix_session script which has to be autostarted within the robot's Citrix session.
	   The PowerShell script can be called from the autostart folder using the batch script.

The check requires Citrix Workspace and storebrowse, which comes with Workspace, as well as send_nsca for Windows (to report check result to Nagios).
Place the check_citrix_logon folder somewhere (e.g. under C:\Robot) and edit the check script to your needs.
Place the log and run script in the Citrix session and edit them to your needs.
Create a service named after each desktop or app you're testing in Nagios. Remeber to turn off active check.

Execute the following command in the scheduled task:
powershell.exe -Command "& 'C:\Robot\check_citrix_logon\check_citrix_logon.ps1' -AppName 'My App' -Warning 60 -Critical 90; exit $LASTEXITCODE"

The scheduled task will get the script exit code as result which can be used for further monitoring of the scheduled task itself.
0 = OK, 1 = Warning, 2 = Critical and 3 = Unknown.
