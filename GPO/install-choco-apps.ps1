﻿$RegCheck = 'DefaultApps'
$version = 1
$RegRoot= "HKLM"
if (Test-Path "$RegRoot`:\Software\Ucorp") {
    try{
        $regexist = Get-ItemProperty "$RegRoot`:\Software\Ucorp" -Name $RegCheck -ErrorAction Stop
    }catch{
        $regexist = $false
    }
} 
else {
    New-Item "$RegRoot`:\Software\Ucorp"
}    
if ((!($regexist)) -or ($regexist.$RegCheck -lt $Version)) {
    try{
        Set-ExecutionPolicy Bypass -Scope Process -Force
        iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

        choco install adobereader -y

        $location = "C:\Users\Public\Desktop\"
        if(Test-Path $location){
            #Remove-Item "$location\*"
        }
        else{
            Write-Output "Directory does not exist"
        }
    }catch{
        write-errror 'unable to install default choco apps'
        break 
    }

    if(!($regexist)){
        New-ItemProperty "$RegRoot`:\Software\Ucorp" -Name $RegCheck -Value $Version -PropertyType string
    }else{
        Set-ItemProperty "$RegRoot`:\Software\Ucorp" -Name $RegCheck -Value $version
    }
}