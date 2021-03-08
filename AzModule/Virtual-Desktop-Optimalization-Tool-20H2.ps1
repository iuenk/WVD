$path ="C:\Packages\"
$ErrorActionPreference = 'SilentlyContinue'

$OptimalizationToolURL="https://ucorpwvdstorage.blob.core.windows.net/wvdfilerepo/Virtual-Desktop-Optimization-Tool-custom-20h2.zip?sp=r&st=2021-01-07T09:09:51Z&se=2022-01-07T17:09:51Z&spr=https&sv=2019-12-12&sr=b&sig=bJN4T5QWwrMwyomQj6sJRsVcxsM99nH%2FzVdTsq778%2Fw%3D"
$installerFile="Virtual-Desktop-Optimization-Tool-master-Custom.zip"

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

mkdir $path -ErrorAction SilentlyContinue
Invoke-WebRequest $OptimalizationToolURL -OutFile $path\$installerFile
Expand-Archive $path\$installerFile -DestinationPath $path
Set-Location $path\Virtual-Desktop-Optimization-Tool-master
.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2009 -Verbose

Set-ExecutionPolicy -ExecutionPolicy Restricted -Force