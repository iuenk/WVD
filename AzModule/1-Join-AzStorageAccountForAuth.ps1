#Define parameters
$TenantId = "a2de9bda-ffed-4527-96d7-d6f3ac10da8c"
$SubscriptionId = "438eedbe-4df3-42b6-9bd2-5b7f8a069f4b"
$ResourceGroupName = "ucorp-storage-rg"
$StorageAccountName = "ucorpwvdstorage"
$ServicePrincipalName = "githubactionazure"
$servicePrincipalApplicationID = (Get-AzADServicePrincipal | Where-Object{$_.DisplayName -eq $ServicePrincipalName} | select -ExpandProperty Id)
$servicePrincipalPassword = "accesskey"

$path ="C:\AzFilesHybrid"
$ErrorActionPreference = 'SilentlyContinue'

$OptimalizationToolURL="https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip"
$installerFile="AzFilesHybrid.zip"

#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

mkdir $path -ErrorAction SilentlyContinue
Invoke-WebRequest $OptimalizationToolURL -OutFile $path\$installerFile
Expand-Archive $path\$installerFile -DestinationPath $path
Set-Location $path\

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

#Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

#Create ServicePrincipal Credential
$ServicePrincipalCreds = New-Object System.Management.Automation.PSCredential($servicePrincipalApplicationID, (ConvertTo-SecureString $servicePrincipalPassword -AsPlainText -Force))

#Authenticatie against the WVD Tenant
Connect-AzAccount -ServicePrincipal -Credential $ServicePrincipalCreds  -Tenant $TenantId

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM").
Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -DomainAccountType "ComputerAccount"

#Run the command below if you want to enable AES 256 authentication. If you plan to use RC4, you can skip this step.
#Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
#Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose