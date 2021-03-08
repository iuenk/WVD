$path ="C:\Packages\"
$ErrorActionPreference = 'SilentlyContinue'

$OptimalizationToolURL="https://github.com/iuenk/WVD/blob/main/AzModule/Virtual-Desktop-Optimization-Tool-custom-20h2.zip?raw=true"
$installerFile="Virtual-Desktop-Optimization-Tool-custom-20h2.zip"

mkdir $path -ErrorAction SilentlyContinue
Invoke-WebRequest $OptimalizationToolURL -OutFile $path\$installerFile
Expand-Archive $path\$installerFile -DestinationPath $path
Set-Location $path\Virtual-Desktop-Optimization-Tool-master
.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2009 -Verbose
