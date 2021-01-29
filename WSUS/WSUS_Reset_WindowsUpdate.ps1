Write-Host "Stopping services..."
Stop-Service -Name BITS
Stop-Service -Name wuauserv
Stop-Service -Name appidsvc
Stop-Service -Name cryptsvc

Write-Host "Remove data files and folders..."
Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue
Remove-Item $env:systemroot\SoftwareDistribution -Recurse -ErrorAction SilentlyContinue
Remove-Item $env:systemroot\System32\Catroot2 -Recurse -ErrorAction SilentlyContinue
Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue

Write-Host "Resetting services..."
"sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
"sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"

Write-Host "Registering DLLs..."
Set-Location $env:systemroot\system32
regsvr32.exe /s atl.dll
regsvr32.exe /s urlmon.dll
regsvr32.exe /s mshtml.dll
regsvr32.exe /s shdocvw.dll
regsvr32.exe /s browseui.dll
regsvr32.exe /s jscript.dll
regsvr32.exe /s vbscript.dll
regsvr32.exe /s scrrun.dll
regsvr32.exe /s msxml.dll
regsvr32.exe /s msxml3.dll
regsvr32.exe /s msxml6.dll
regsvr32.exe /s actxprxy.dll
regsvr32.exe /s softpub.dll
regsvr32.exe /s wintrust.dll
regsvr32.exe /s dssenh.dll
regsvr32.exe /s rsaenh.dll
regsvr32.exe /s gpkcsp.dll
regsvr32.exe /s sccbase.dll
regsvr32.exe /s slbcsp.dll
regsvr32.exe /s cryptdlg.dll
regsvr32.exe /s oleaut32.dll
regsvr32.exe /s ole32.dll
regsvr32.exe /s shell32.dll
regsvr32.exe /s initpki.dll
regsvr32.exe /s wuapi.dll
regsvr32.exe /s wuaueng.dll
regsvr32.exe /s wuaueng1.dll
regsvr32.exe /s wucltui.dll
regsvr32.exe /s wups.dll
regsvr32.exe /s wups2.dll
regsvr32.exe /s wuweb.dll
regsvr32.exe /s qmgr.dll
regsvr32.exe /s qmgrprxy.dll
regsvr32.exe /s wucltux.dll
regsvr32.exe /s muweb.dll
regsvr32.exe /s wuwebv.dll

Write-Host "Removing Windows Update settings..."
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f

Write-Host "Resetting WinSock..."
netsh winsock reset
netsh winhttp reset proxy

Write-Host "Deleting BITS jobs..."
Get-BitsTransfer | Remove-BitsTransfer

Write-Host "Installing Windows Update Agent..."
wusa Windows8-RT-KB2937636-x64 /quiet

Write-Host "Starting services..."
Start-Service -Name BITS
Start-Service -Name appidsvc
Start-Service -Name cryptsvc

Write-Host "Running discovery..."
Stop-Service -Name wuauserv
Set-Service -Name wuauserv -StartupType Manual
gpupdate /force
wuauclt /resetauthorization /detectnow

Write-Host "Done!"