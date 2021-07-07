#Define parameters
$TenantId = "a2de9bda-ffed-4527-96d7-d6f3ac10da8c"
$SubscriptionId = "438eedbe-4df3-42b6-9bd2-5b7f8a069f4b"
$ResourceGroup = "ucorp-storage-rg"
$StorageAccountStd = "ucorpwvdstd"
$StorageAccountPrem = "ucorpwvdprem"
$OU = "OU=SA,DC=ucorp,DC=local"
$SecurityGroupUsers = "SG_WVD_Users"
$SecurityGroupAdmins = "SG_WVD_Admins"
$ServicePrincipalName = "githubactionazure"
$servicePrincipalApplicationID  = (Get-AzADServicePrincipal -DisplayName $ServicePrincipalName).Id
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
Import-Module .\AzFilesHybrid.psd1

#Create ServicePrincipal Credential
$ServicePrincipalCreds = New-Object System.Management.Automation.PSCredential($servicePrincipalApplicationID, (ConvertTo-SecureString $servicePrincipalPassword -AsPlainText -Force))

#Authenticatie against the WVD Tenant
Connect-AzAccount -ServicePrincipal -Credential $ServicePrincipalCreds  -Tenant $TenantId

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM").
Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccountStd -DomainAccountType "ComputerAccount" -OrganizationalUnitDistinguishedName $OU
Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccountPrem -DomainAccountType "ComputerAccount" -OrganizationalUnitDistinguishedName $OU

$fslogixOffice = "fslogixoffice"
$fslogixProfiles = "fslogixprofiles"
$Msix = "msixappattach"

# rechten nog zetten op de shares
$SecurityGroupIDUsers = (Get-AzADGroup -DisplayName $SecurityGroupUsers).id
$SecurityGroupIDAdmins = (Get-AzADGroup -DisplayName $SecurityGroupAdmins).id
$fslogixOfficeId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountPrem/fileServices/default/fileshares/$fslogixOffice"
$fslogixProfilesId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountPrem/fileServices/default/fileshares/$fslogixProfiles"
$MsixId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountStd/fileServices/default/fileshares/$Msix"

# To give WVD users to the file share (Kerberos), enable identity-based authentication for the storage account
New-AzRoleAssignment -ObjectID $SecurityGroupIDUsers -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $fslogixOfficeId
New-AzRoleAssignment -ObjectID $SecurityGroupIDUsers -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $fslogixProfilesId
New-AzRoleAssignment -ObjectID $SecurityGroupIDUsers -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $MsixId

# To give WVD admins to the file share (Kerberos), enable identity-based authentication for the storage account
New-AzRoleAssignment -ObjectID $SecurityGroupIDAdmins -RoleDefinitionName "Storage File Data SMB Share Elevated Contributor" -Scope $fslogixOfficeId
New-AzRoleAssignment -ObjectID $SecurityGroupIDAdmins -RoleDefinitionName "Storage File Data SMB Share Elevated Contributor" -Scope $fslogixProfilesId
New-AzRoleAssignment -ObjectID $SecurityGroupIDAdmins -RoleDefinitionName "Storage File Data SMB Share Elevated Contributor" -Scope $MsixId

#Mount storage accounts as shares to set NTFS rights
$storageKeyStd = (Get-AzstorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccountStd).Value[0]
$storageKeyPrem = (Get-AzstorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccountPrem).Value[0]

Invoke-Expression -Command "cmdkey /add:$StorageAccountStd.file.core.windows.net /user:AZURE\$StorageAccountStd /pass:$storageKeyStd"
Invoke-Expression -Command "cmdkey /add:$StorageAccountPrem.file.core.windows.net /user:AZURE\$StorageAccountPrem /pass:$storageKeyPrem"

#From here adjust the NTFS rights manually
#$storageKeyStd
#$storageKeyPrem
#New-PSDrive -Name M -PSProvider FileSystem -Root "\\ucorpwvdstd.file.core.windows.net\msixappattach"
#New-PSDrive -Name F -PSProvider FileSystem -Root "\\ucorpwvdprem.file.core.windows.net\fslogixprofiles"
#New-PSDrive -Name P -PSProvider FileSystem -Root "\\ucorpwvdprem.file.core.windows.net\fslogixoffice"

#msixappattach
#SYSTEM (full control)
#SG_WVD_Admins (Full control)
#Domain Admins (Full control)
#Domain Computers (Read, Modify, Execute)

#fslogixprofiles
#Domain Admins (Full control)
#SG_WVD_Admins (Full control)
#SG_WVD_Users (Modify, this folder only)
