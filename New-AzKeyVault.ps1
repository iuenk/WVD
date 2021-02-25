$Customer = "UCORP"
$TenantId = "a2de9bda-ffed-4527-96d7-d6f3ac10da8c"
$SubscriptionId = "438eedbe-4df3-42b6-9bd2-5b7f8a069f4b"
$ResourceGroupName = "Ucorp-Vault-RG"

$domainadminuser = ConvertTo-SecureString "iuenk-a@ucorp.nl" -AsPlainText -Force
$domainadminpassword = ConvertTo-SecureString "ZwemmenZwemmen1!" -AsPlainText -Force
$domainname = ConvertTo-SecureString "ucorp.local" -AsPlainText -Force
$domainoupath = ConvertTo-SecureString "OU=WVD,OU=Ucorp,DC=ucorp,DC=local" -AsPlainText -Force

Connect-AzAccount -Tenant $TenantId -SubscriptionId $SubscriptionId

$RGCheck = Get-AzResourceGroup | ?{$_.ResourceGroupName -eq $ResourceGroupName}
if($RGCheck -eq $null){
New-AzResourceGroup -name "Ucorp-Vault-RG" -Location "westeurope"
}
Else{
    write-host "$ResourceGroupName already exists"
}

New-AzKeyVault -Name "Ucorp-WVD-KV" -ResourceGroupName $ResourceGroupName -Location "westeurope"
Set-AzKeyVaultAccessPolicy -VaultName "Ucorp-WVD-KV" -UserPrincipalName "iuenk-a@ucorp.nl" -PermissionsToSecrets get,set,delete,list
Set-AzKeyVaultAccessPolicy -VaultName "Ucorp-WVD-KV" -ObjectId "f7f33d28-5b73-43c3-a7b5-655a7c307221" -PermissionsToSecrets get,set,delete,list

Set-AzKeyVaultSecret -VaultName "Ucorp-WVD-KV" -Name "domainadminuser" -SecretValue $domainadminuser
Set-AzKeyVaultSecret -VaultName "Ucorp-WVD-KV" -Name "domainadminpassword" -SecretValue $domainadminpassword
Set-AzKeyVaultSecret -VaultName "Ucorp-WVD-KV" -Name "domainname" -SecretValue $domainname
Set-AzKeyVaultSecret -VaultName "Ucorp-WVD-KV" -Name "domainoupath" -SecretValue $domainoupath