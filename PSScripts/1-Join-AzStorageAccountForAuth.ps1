#Define parameters
$TenantId = "a2de9bda-ffed-4527-96d7-d6f3ac10da8c"
$SubscriptionId = "438eedbe-4df3-42b6-9bd2-5b7f8a069f4b"
$ResourceGroup = "ucorp-storage-rg"
$StorageAccountStd = "ucorpwvdstd"
$StorageAccountPrem = "ucorpwvdprem"
$OU = "OU=Ucorp,DC=ucorp,DC=local"
$SecurityGroup = "SG_WVD_Users"
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
Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccountStd -DomainAccountType "ComputerAccount" -OrganizationalUnitDistinguishedName $OU
Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccountPrem -DomainAccountType "ComputerAccount" -OrganizationalUnitDistinguishedName $OU

$fslogixOffice = "fslogixoffice"
$fslogixProfiles = "fslogixprofiles"
$Msix = "msixappattach"

# rechten nog zetten op de shares
$SecurityGroupID = (Get-AzADGroup -DisplayName $SecurityGroup).id
$fslogixOfficeId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountPrem/fileServices/default/fileshares/$fslogixOffice"
$fslogixProfilesId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountPrem/fileServices/default/fileshares/$fslogixProfiles"
$MsixId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.storage/storageAccounts/$StorageAccountStd/fileServices/default/fileshares/$Msix"

# To give individual accounts access to the file share (Kerberos), enable identity-based authentication for the storage account
New-AzRoleAssignment -ObjectID $SecurityGroupID -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $fslogixOfficeId
New-AzRoleAssignment -ObjectID $SecurityGroupID -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $fslogixProfilesId
New-AzRoleAssignment -ObjectID $SecurityGroupID -RoleDefinitionName "storage File Data SMB Share Contributor" -Scope $MsixId