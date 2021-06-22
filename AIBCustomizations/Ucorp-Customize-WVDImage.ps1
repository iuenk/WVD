<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder
.NOTES
    Author: Ivo Uenk
    Version: 0.1
#>

#### Create Temporary Installation folder for download resources ###
$path = "c:\Install"
mkdir $path -ErrorAction SilentlyContinue


################################################# Configuring Baseline OS #################################################

### Disable Store auto update ###
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable


### Datum/Tijd/Taal OS (getest, werkt bijna!) ###
#https://docs.microsoft.com/nl-nl/azure/virtual-desktop/language-packs, https://mscloud.be/azure/powershell/configure-regional-settings-and-windows-locales-on-azure-virtual-machines/)

$lp_root_folder = "$path\Language" #Root folder where the copied sourcefiles are
$LanguageUrl = 'https://ucorpwvdstd.blob.core.windows.net/wvdfilerepo/Configure-NL-Language.zip?sp=r&st=2021-06-22T15:19:51Z&se=2023-06-22T23:19:51Z&spr=https&sv=2020-02-10&sr=b&sig=wkgATIu6nMrdYBVHAFdRBWmVquuMGvpB6LmjxYkGAEY%3D'
$architecture = "x64" #Architecture of cab files
$systemlocale = "nl-NL" #System local when script finishes
$Languagefiles = "Configure-NL-Language.zip"

mkdir $lp_root_folder -ErrorAction SilentlyContinue
Invoke-WebRequest $LanguageUrl -OutFile $lp_root_folder\$Languagefiles
Expand-Archive $lp_root_folder\$Languagefiles -DestinationPath $lp_root_folder

$RegionalSettings = "$lp_root_folder\NLRegion.xml"

# Set Locale, language etc. 
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$RegionalSettings`""

# Start installation of language pack on Win10 2004 and higher
foreach ($language in Get-ChildItem -Path "$lp_root_folder\LXP") {
    #check if files exist

    $appxfile = $lp_root_folder + "\LXP\" + $language.Name + "\LanguageExperiencePack." + $language.Name + ".Neutral.appx"
    $licensefile = $lp_root_folder + "\LXP\" + $language.Name + "\License.xml"
    $cabfile = $lp_root_folder + "\LangPack\Microsoft-Windows-Client-Language-Pack_" + $architecture + "_" + $language.Name + ".cab"
   
    if (!(Test-Path $appxfile)) {
        Write-Host $language.Name " - File missing: $appxfile" -ForegroundColor Red
        Write-Host "Skipping installation of "  + $language.Name
    } elseif (!(Test-Path $licensefile)) {
        Write-Host $language.Name " - File missing: $licensefile" -ForegroundColor Red
        Write-Host "Skipping installation of "  + $language.Name
    } elseif (!(Test-Path $cabfile)) {
        Write-Host $language.Name " - File missing: $cabfile" -ForegroundColor Red
        Write-Host "Skipping installation of "  + $language.Name
    } else {
        Write-Host $language.Name " - Installing $cabfile" -ForegroundColor Green
        Start-Process -FilePath "dism.exe" -WorkingDirectory "C:\Windows\System32" -ArgumentList "/online /Add-Package /PackagePath=$cabfile /NoRestart" -Wait

        Write-Host $language.Name " - Installing $appxfile" -ForegroundColor Green
        Start-Process -FilePath "dism.exe" -WorkingDirectory "C:\Windows\System32" -ArgumentList "/online /Add-ProvisionedAppxPackage /PackagePath=$appxfile /LicensePath=$licensefile /NoRestart" -Wait

        Write-Host $language.Name " - CURRENT USER - Add language to preffered languages (User level)" -ForegroundColor Green
        $prefered_list = Get-WinUserLanguageList
        $prefered_list.Add($language.Name)
        Set-WinUserLanguageList($prefered_list) -Force
    }
}

Write-Host "$systemlocale - Setting the system locale" -ForegroundColor Green
Set-WinSystemLocale -SystemLocale $systemlocale
Set-WinUserLanguageList -LanguageList $systemlocale -Force
Set-Culture -CultureInfo $systemlocale
Set-WinHomeLocation -GeoId 176
Set-TimeZone -Name "W. Europe Standard Time"
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\MUI\Settings\ -Name "PreferredUILanguages" -Type MultiString -Value "nl-NL"

For ($i = 0; $i -ne $installed_lp.Count; $i++) {
    Write-Host '$prefered_list.Add(' $installed_lp[$i] ')' -ForegroundColor Blue
}

#Set for new user accounts
Start-Process "C:\$lp_root_folder\DefaultLanguageSettings.bat"

### Set Wallpaper en Fonts ###
#Set Fonts
$FontUrl = 'https://ucorpwvdstd.blob.core.windows.net/wvdfilerepo/Font.zip?sp=r&st=2021-06-22T15:22:16Z&se=2023-06-22T23:22:16Z&spr=https&sv=2020-02-10&sr=b&sig=GjOb1dGTd%2Fg8ebwiX72ZNHmomYho0R5XjW5rgFnHzLQ%3D'
$FontFile = "Font.zip"
Invoke-WebRequest $FontUrl -OutFile $path\$FontFile
Expand-Archive "$path\$FontFile" -DestinationPath $path
$FontFolder = "$path\Font"

foreach ($Font in Get-ChildItem -Path $FontFolder -File) {
    $dest = "C:\Windows\Fonts\$font"
    if (Test-Path -Path $dest) {
        "Font $font already installed."
    }
    else {
        $font | Copy-Item -Destination $dest
    }
}

#Set Wallpaper
$WallpaperUrl = 'https://ucorpwvdstd.blob.core.windows.net/wvdfilerepo/Ucorp-Wallpaper.jpg?sp=r&st=2021-06-22T15:20:46Z&se=2023-06-22T23:20:46Z&spr=https&sv=2020-02-10&sr=b&sig=hqcH6QFr7QK2uWRr6H8%2FBlLXdO1EVB8uPUSlSJ8EjU4%3D'
$WallpaperLocation = 'C:\Windows\Web\Wallpaper\Ucorp-Wallpaper.jpg'
Invoke-WebRequest -Uri $WallpaperUrl -OutFile $WallpaperLocation


### Add MSIX app attach certificate ###
Invoke-WebRequest -Uri 'https://gsvwvdstd.blob.core.windows.net/gsvwvdrepo/GSV-MSIX.pfx?sp=r&st=2021-05-27T20:35:26Z&se=2025-05-28T04:35:26Z&spr=https&sv=2020-02-10&sr=b&sig=ov5DcGkwTmkAdSt2b8W77Ne5LCd1IJP5rxbquexcLdU%3D' -OutFile "$path\MSIXAppAttach.pfx"
Import-PfxCertificate -FilePath "$path\MSIXAppAttach.pfx.pfx" -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' -Password (ConvertTo-SecureString -String 'Zwemmen1!' -AsPlainText -Force) -Exportable


### MSIX app attach mounten ###
# Add MSIX storage account credentials as system needed to mount packages at session hosts
$PsExecUrl = 'https://ucorpwvdstd.blob.core.windows.net/wvdfilerepo/PsExec.zip?sp=r&st=2021-06-22T20:17:10Z&se=2023-06-23T04:17:10Z&spr=https&sv=2020-02-10&sr=b&sig=U1nmgyKXmBRXY6XjxT3%2BGbIkanrE1O30RERqv7EtsG4%3D'
$PsExecfile = 'PsExec.zip'

Invoke-WebRequest $PsExecUrl -OutFile $path\$PsExecfile
Expand-Archive $path\$PsExecfile -DestinationPath "C:\Windows\System32" -Force

$PSExecString = "C:\Windows\System32\PsExec.exe -s -accepteula -nobanner cmdkey /add:ucorpwvdstd.file.core.windows.net /user:AZURE\ucorpwvdstd /pass:DwtWjATH93vYsarh9SRnbLa+dCTy6w5XeC4xq088PfX2gjB6cYbe7pwdMnK5as7IfunAcb9jzdFwjDzc2W1wRA=="
Invoke-Expression -Command ("$PSExecString")


################################################# Installing Applications #################################################
### Install Teams and WebSocket Optimizations client ###
reg add "HKLM\SOFTWARE\Microsoft\Teams\" /v IsWVDEnvironment /t REG_DWORD /d 1 /f
Invoke-WebRequest -Uri 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true' -OutFile 'c:\Install\Teams_windows_x64.msi'
Invoke-Expression -Command 'C:\Install\Teams_windows_x64.msi OPTIONS="noAutoStart=true" ALLUSERS=1 ALLUSER=1'
Start-Sleep -Seconds 20

Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt' -OutFile 'C:\Install\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi'
Invoke-Expression -Command 'C:\Install\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi /quiet' 
Start-Sleep -Seconds 5


# Turn off Teams startup for HKLM will also be done with User GPO
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
$CustomInput = "11,00,00,00,c0,bb,ab,a4,9a,66,d7,01"
$hexified = $CustomInput.Split(',') | ForEach-Object { "0x$_"}
$AttrName = "Teams"
Set-ItemProperty -Path $Key -Name $AttrName -Value ([byte[]]$hexified) -verbose -ErrorAction 'Stop'


### Install Microsoft 365 Apps with customization ###
Invoke-WebRequest -Uri 'https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=languagepack&language=nl-nl&platform=x64&source=O16LAP&version=O16GA' -OutFile 'C:\Install\OfficeSetup.exe'
Invoke-WebRequest -Uri 'https://ucorpwvdstd.blob.core.windows.net/wvdfilerepo/OfficeConfiguration.xml?sp=r&st=2021-06-22T20:23:20Z&se=2023-06-23T04:23:20Z&spr=https&sv=2020-02-10&sr=b&sig=G2Tj5AUlse1%2BUmAvWYAhzHozIbdcrW6PgWWUgSX75Jk%3D' -OutFile 'C:\Install\OfficeConfiguration.xml'

Invoke-Expression -command 'C:\Install\OfficeSetup.exe /configure OfficeConfiguration.xml'
Start-Sleep -Seconds 300


### Configure Chocolatey ###
$TaskFolder = 'GSV'
$TaskName = 'UpdateChocoApps'

Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

choco install adobereader -params '"/NoUpdates"' -y

$A = New-ScheduledTaskAction -Execute "Powershell" -Argument "-command & {choco upgrade all -y}"
$T = New-ScheduledTaskTrigger -Daily -At 11am
$P = New-ScheduledTaskPrincipal -UserId 'system'
$S = New-ScheduledTaskSettingsSet -StartWhenAvailable
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
Register-ScheduledTask  -TaskName "$TaskFolder\$TaskName" -InputObject $D -ErrorAction SilentlyContinue