<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder
.NOTES
    Author: Ivo Uenk
    Version: 0.1
#>

############################################## Create Temporary Installation folder (for downloaded resources) ##############################################
New-Item -Path 'C:\Install' -ItemType Directory -Force | Out-Null


############################################## Datum/Tijd/Taal OS ############################################## 
#NL taalinstellen (zie https://docs.microsoft.com/nl-nl/azure/virtual-desktop/language-packs en https://mscloud.be/azure/powershell/configure-regional-settings-and-windows-locales-on-azure-virtual-machines/)
#Herstart nodig
#Pas tijdzone aan naar UTC +1
#Ga naar Configuratiescherm, klik en regio, dan Land/regio en tablad Beheer: Instellingen kopieren. Selecteer Aanmeldingsscherm en systeemaccounts en Nieuwe gebruikersaccounts.
#Zie Set-RegionalSettings.ps1

############################################## Disable Store auto update ##############################################
#Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Automatic app update" /Disable (is niet aanwezig)
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable


############################################## Configure OneDrive for All Users ##############################################
# Uninstall Onedrive
taskkill.exe /F /IM "OneDrive.exe"
Write-Output "Remove OneDrive"

if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
}

# Install OneDrive (check if OneDrive link is still valid)
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkID=844652&clcid=0x413&culture=nl-nl&country=NL' -OutFile 'c:\Install\OneDriveSetup.exe'
Invoke-Expression -Command 'C:\Install\OneDriveSetup.exe /allusers'
Start-Sleep -Seconds 20


############################################## Install Teams ##############################################
reg add "HKLM\SOFTWARE\Microsoft\Teams\" /v IsWVDEnvironment /t REG_DWORD /d 1 /f
Invoke-WebRequest -Uri 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true' -OutFile 'c:\Install\Teams_windows_x64.msi'
Invoke-Expression -Command 'C:\Install\Teams_windows_x64.msi OPTIONS="noAutoStart=true" ALLUSERS=1 ALLUSER=1'
Start-Sleep -Seconds 20

# Turn off auto start Teams
#HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run\com.squirrel.Teams.Teams

# Install Teams WebSocket Optimizations client
Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt' -OutFile 'c:\Install\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi'
Invoke-Expression -Command 'C:\Install\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi /silent' 
Start-Sleep -Seconds 5


############################################## Install M365 NL ##############################################
Invoke-WebRequest -Uri 'https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=languagepack&language=nl-nl&platform=x64&source=O16LAP&version=O16GA' -OutFile 'c:\Install\OfficeSetup.exe'
Invoke-Expression -Command 'C:\Install\OfficeSetup.exe'
Start-Sleep -Seconds 300

############################################## Install Citrix Workspace App ##############################################


############################################## Add MSIX app attach certificate ##############################################
Invoke-WebRequest -Uri 'https://gsvwvdstd.blob.core.windows.net/gsvwvdrepo/GSV-MSIX.pfx?sp=r&st=2021-05-27T20:35:26Z&se=2025-05-28T04:35:26Z&spr=https&sv=2020-02-10&sr=b&sig=ov5DcGkwTmkAdSt2b8W77Ne5LCd1IJP5rxbquexcLdU%3D' -OutFile 'c:\Install\GSV-MSIX.pfx'
Import-PfxCertificate -FilePath 'C:\Install\GSV-MSIX.pfx' -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' -Password (ConvertTo-SecureString -String 'Solvinity@GSV' -AsPlainText -Force) -Exportable

############################################## Set File Type Associations ##############################################
Dism.exe /Online /Import-DefaultAppAssociations:C:\DefaultAssoc.xml
https://raw.githubusercontent.com/iuenk/WVD/main/asdasdasd



############################################## MSIX app attach mounten ##############################################
#maakt het mounten van images mogelijk SeManageVolumePrivilege en geeft de tools om bestanden op te vragen van Azure file share onder system
#Kopieer de PSTools https://docs.microsoft.com/en-us/sysinternals/downloads/psexec naar %Windir%\System32
# Add MSIX storage account credentials as system needed to mount packages at session hosts
$PSExecString = "C:\Windows\System32\PsExec.exe -s -accepteula -nobanner cmdkey /add:gsvwvdstd.file.core.windows.net /user:AZURE\storageaccount /pass:wachtwoord"
Invoke-Expression -Command ("$PSExecString")
