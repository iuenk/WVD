<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder
.NOTES
    Author: Ivo Uenk
    Version: 0.1

    Research Links: 
#>

## Create Temporary Installation folder (for downloaded resources)
$path ="c:\Install"
mkdir $path -Force

$CustomerPrefix = "Ucorp"
$TenantGUID = (get-aztenant).Id


## Configure OneDrive
$OneDriveURL="https://go.microsoft.com/fwlink/?linkid=2083517"
$OneDriveInstallerFile="OneDriveSetup.exe"
$HKLMregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
$DiskSizeregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\DiskSpaceCheckThresholdMB'##Path to max disk size key
$KFMSilentOptIn = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'

Invoke-WebRequest $OneDriveURL -OutFile $path\$OneDriveInstallerFile
"$path\$OneDriveInstallerFile /allusers"

# Wait till installation is completed
Start-Sleep -Seconds 20

IF(!(Test-Path $HKLMregistryPath))
{New-Item -Path $HKLMregistryPath -Force}
IF(!(Test-Path $DiskSizeregistryPath))
{New-Item -Path $DiskSizeregistryPath -Force}
New-ItemProperty -Path $HKLMregistryPath -Name 'SilentAccountConfig' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable silent account configuration
New-ItemProperty -Path $DiskSizeregistryPath -Name $TenantGUID -Value '102400' -PropertyType DWORD -Force | Out-Null ##Set max OneDrive threshold before prompting
New-ItemProperty -Path $KFMSilentOptIn -Name 'KFMSilentOptIn' -Value $TenantGUID -Force | Out-Null ##Silent redirect known folders to Onedrive


## Configure FSlogix
$fsLogixURL="https://aka.ms/fslogix_download"
$installerFile="fslogix_download.zip"

Try
{
    Invoke-WebRequest $fsLogixURL -OutFile $path\$installerFile
    Expand-Archive $path\$installerFile -DestinationPath $path\fsLogix\extract
    Start-Process -FilePath $path\fsLogix\extract\x64\Release\FSLogixAppsSetup.exe -Args "/install /quiet /norestart" -Wait
    Write-Host "Fslogix Install Succeeded"
    
}
Catch
{
    Write-Host "Fslogix Install Failed"
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage
    $FailedItem = $_.Exception.ItemName
    Write-Host $FailedItem
} 


## Configure Teams
reg add "HKLM\SOFTWARE\Microsoft\Teams\" /v IsWVDEnvironment /t REG_DWORD /d 1 /f
$TeamsURL = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
$TeamsInstaller = "Teams_windows_x64.msi"
$WebRTCURL = "https://aka.ms/vs/16/release/vc_redist.x64.exe"
$WebRTCInstaller = "vc_redist.x64.exe"

Invoke-WebRequest $TeamsURL -OutFile $path\$TeamsInstaller
Invoke-WebRequest $WebRTCURL -OutFile $path\$WebRTCInstaller 

Start-Process msiexec.exe -Wait -ArgumentList '/I $path\Teams_windows_x64.msi OPTIONS="noAutoStart=true" ALLUSERS=1 ALLUSER=1'
Start-Sleep -Seconds 20

Start-Process -FilePath $path\vc_redist.x64.exe -Args "/quiet /norestart" -Wait

#Disable auto-updates
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
#Time zone redirection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f
#Disable Storage Sense
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f

# add MSIX app attach certificate

#maakt het mounten van images mogelijk SeManageVolumePrivilege en geeft de tools om bestanden op te vragen van Azure file share onder system
#Kopieer de PSTools https://docs.microsoft.com/en-us/sysinternals/downloads/psexec naar %Windir%\System32

#Maak in %Windir%\System32 een CMD bestand aan met de naam setPrivGpsvc en inhoud:
#sc privs gpsvc SeManageVolumePrivilege/SeTcbPrivilege/SeTakeOwnershipPrivilege/SeIncreaseQuotaPrivilege/SeAssignPrimaryTokenPrivilege/SeSecurityPrivilege/SeChangeNotifyPrivilege/SeCreatePermanentPrivilege/SeShutdownPrivilege/SeLoadDriverPrivilege/SeRestorePrivilege/SeBackupPrivilege/SeCreatePagefilePrivilege

#Open CMD als administrator en voer het volgende uit:
#psexec /s cmd
#setPrivGpsvc

#bloadware eraf

# NL taalinstellingen
#zie https://docs.microsoft.com/nl-nl/azure/virtual-desktop/language-packs)
#Herstart nodig
#Pas tijdzone aan naar UTC +1


# SIG # Begin signature block
# MIINHAYJKoZIhvcNAQcCoIINDTCCDQkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQUqfjLZyyTMB1rjICtSSedxX
# MzagggpeMIIFJjCCBA6gAwIBAgIQCyXBE0rAWScxh3bGfykLTjANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDgxMDAwMDAwMFoXDTIzMDgx
# NTEyMDAwMFowYzELMAkGA1UEBhMCTkwxDzANBgNVBAcTBkxlbW1lcjEVMBMGA1UE
# ChMMY29nbml0aW9uIElUMRUwEwYDVQQLEwxDb2RlIFNpZ25pbmcxFTATBgNVBAMT
# DGNvZ25pdGlvbiBJVDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL2y
# YRbztz9wTtatpSJ5NMD0JZtDPhuFqAVTjoGc1jvn68M41zlGgi8fVvEccaH3nDTT
# 6T8edgFuEbsZVHZGmY109zHOPwXX+Zvp3T+Hk2Ys8Liwwirr6xw9dlneBu85j8gd
# Mamz+mNjzpyBg1eVlD7cV1JAL3oAXgONRiebdpD6DPvd3melPmeg84Un3VV6+W8M
# 8Y0Pec+TbxIda18Lr4DqnIl0a/Suk8kQ2DzZXDXoK+MCfA6zsqyEOSY5yI5OwdU0
# 93LC2PHFEKEkIogBlCiD0UQDbamPdu7wZnTAHPTDfifdMhCPLBA0y4pj4jm6ggFE
# 3ZuQMR/yU8JXSwy72ZECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl
# 6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBR2SeoVDh3RxGqV5iamn/FFU6J65zAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOg
# MYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEW
# HGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEF
# BQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBO
# BggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJ
# KoZIhvcNAQELBQADggEBAL4Zda674x5WLL8B059a9cxnUIC05LcjD/3hkCLZgbMa
# krDrfsjNpA+KpMiTv2TW5pDRCXGJirJO27XRTojr2F8+gJAyIB+8ZLiyKmy3IcCV
# DXjjb6i/4TiGbDmGL3Ctl5pmWRpksnr3TKSMyxz2OogLS6w9pgRdA1hgJSfZMV+a
# KRrd4iW5YWKIwFZlYDeQqpBBtQ6ujzgQ/04FcmjyOlNch4hofJVLauzkSb1Tnzt1
# 6TyT2pJ9BzasoOlxYEFhn0ikXndlKVBb7gpFInqSf5DJtaVRIXojj0eqN6LZroUz
# 62m2YeR29uC06xcdF7fjo+YKxe+kdApdPfX0Nx9Moc8wggUwMIIEGKADAgECAhAE
# CRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# JDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIx
# MjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMT
# KERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmx
# OttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfT
# xvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6Ygs
# IJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tK
# tel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0
# xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGj
# ggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYD
# VR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCG
# SAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
# L0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1Dlgw
# HwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQAD
# ggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBV
# N7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEb
# Bw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZ
# cbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRr
# sutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKU
# GIUukpHqaGxEMrJmoecYpJpkUe8xggIoMIICJAIBATCBhjByMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWdu
# aW5nIENBAhALJcETSsBZJzGHdsZ/KQtOMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRBfeNiVPF4
# YnkL9x6aDUXLudc/wjANBgkqhkiG9w0BAQEFAASCAQCd52MMT/Dqo3th0g+7gaEX
# QYwJBt1j2Xu7aM5r8FYfPEWgk/hxzgT6p+BkEqxT4dsobEhOf5ULd8ULFz1Rtb40
# +ZyQN+6yLX2nyn57zuvr44tpebKEKp7pmolyXwjj4Wzn1GcsmFiwDfZ0KbmeKHHc
# plcZw1tHK9Vq0DzvIlDzEePFEiCTCxCkWfg6A4VbtICGL1d0QknFOho8Mu/exGHA
# 1aq3xpURXniXzrG/qDaYurRTH4QW+tmsdYEpdf5tzrna9gaL5qryI1EKCJaM74BV
# T594ljdUBHjGDI5GcVRlj+EGdwmABYyvd1CwvUq5MoR6kz06N89ANVIpH708xsxb
# SIG # End signature block
