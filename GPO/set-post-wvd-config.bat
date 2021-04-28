rem Disable Store auto update
reg add HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 0 /f
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Automatic app update" /Disable
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable

rem Disable Content Delivery auto download apps that they want to promote to users
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug /v ContentDeliveryAllowedOverride /t REG_DWORD /d 0x2 /f

CD C:\Windows\System32
.\PsExec.exe -s -accepteula -nobanner cmdkey /add:ucorpwvdstd.file.core.windows.net /user:AZURE\ucorpwvdstd /pass:DwtWjATH93vYsarh9SRnbLa+dCTy6w5XeC4xq088PfX2gjB6cYbe7pwdMnK5as7IfunAcb9jzdFwjDzc2W1wRA==
.\PsExec.exe -s -accepteula -nobanner cmd.exe