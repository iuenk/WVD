#############################
# Install Language pack Win10 2004 and higher
#
# This tool installs the needed CAB and APPX packages
#
# The cab and appx files needs to be installed as Admin
#
# To activate the languages, this should be started as user and is marked at the end of this script
#
###############################################

# Variables
$lp_root_folder = "C:\Install\Language" #Root folder where the copied sourcefiles are
$architecture = "x64" #Architecture of cab files
$systemlocale = "nl-NL" #System local when script finishes
$LanguageFilesURL = 'https://gsvwvdstd.blob.core.windows.net/gsvwvdrepo/Configure-NL-Language.zip?sp=r&st=2021-05-29T20:59:14Z&se=2023-05-30T04:59:14Z&spr=https&sv=2020-02-10&sr=b&sig=YYyPw%2BHw60tw3oF8iz5EnNW%2BH5uVWieTZZjhw8LrDPM%3D'
$Languagefiles = "Configure-NL-Language.zip"

Invoke-WebRequest $fsLogixURL -OutFile $path\$Languagefiles
Expand-Archive $path\$Languagefiles -DestinationPath $path

$RegionalSettings = "$path\NLRegion.xml"

# Set Locale, language etc. 
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$RegionalSettings`""

# Start installation of language pack on Win10 2004 and higher
foreach ($language in Get-ChildItem -Path "$path\LXP") {
    #check if files exist

    $appxfile = $path + "\LXP\" + $language.Name + "\LanguageExperiencePack." + $language.Name + ".Neutral.appx"
    $licensefile = $path + "\LXP\" + $language.Name + "\License.xml"
    $cabfile = $path + "\LangPacks\Microsoft-Windows-Client-Language-Pack_" + $architecture + "_" + $language.Name + ".cab"
   
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

        $path.Add($language.Name)
    }
}

# Set languages/culture. Not needed perse.
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