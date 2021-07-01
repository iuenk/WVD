<#PSScriptInfo
.VERSION 1.0
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Reboots VMs in a HostPool
.DESCRIPTION
  This will iterate through the VMs registered to a host pool and reboot them. 
.NOTES
  Version:        1.0
  Author:         Ivo Uenk
  Creation Date:  2021-07-01
  Purpose/Change: Initial script development
#>

workflow GSV-WVD-Reboot-Pool

{
    Param (
    #Script parameters go here
    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolResourceGroupName,
        
    [Parameter(mandatory = $false)]
    [switch]$SkipIfActiveSessions,

    [Parameter(mandatory = $false)]
    [switch]$OnlyDoIfNeedsAssistance
    )

    $ErrorActionPreference = 'SilentlyContinue'

    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName       
        "Logging in to Azure..."
        Connect-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    Write-Output "Starting to Enable Boot Diagnostics for VMs in Host Pool $HostPoolName ..."
    if ($OnlyDoIfNeedsAttention) {
        Write-Output "!! Only hosts flagged as 'Needs Assistance' will be rebooted !!"
    }
    if ($SkipIfActiveSessions) {
        Write-Output "!! Only hosts with zero sessions will be rebooted !!"
    }

    $rebooted = 0
    $skippedSessions = 0
    $skippedOK = 0
    $shutdown = 0

    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroupName -HostPoolName $HostPoolName
    foreach ($sh in $sessionHosts) {
        

        # Name is in the format 'host-pool-name/vmname.domainfqdn' so need to split the last part
        $VMName = $sh.Name.Split("/")[1]
        $VMName = $VMName.Split(".")[0]
        
        $Session = $sh.Session
        $Status = $sh.Status
        $UpdateState = $sh.UpdateState
        $UpdateErrorMessage = $sh.UpdateErrorMessage

        Write-output "=== Starting Reboot for VM: $VMName"
        Write-output "Session: $Session"
        Write-output "Status: $Status"
        Write-output "UpdateState: $UpdateState"
        Write-output "UpdateErrorMessage: $UpdateErrorMessage"

        if ($Status -ne "Unavailable") {
            if ($Status -ne "NeedsAssistance" -and $OnlyDoIfNeedsAssistance ) {
                $skippedOK += 1
                Write-output "!! The VM '$VMName' is not in 'Needs Assistance' state, so will NOT be rebooted. !!"       
            }
            elseif ($SkipIfActiveSessions -and $Session -gt 0) {
                $skippeSessions += 1
                Write-output "!! The VM '$VMName' has $Session session(s), so will NOT be rebooted. !!"       
            }
            else {
                $rebooted += 1
                Restart-AzVM -ResourceGroupName $HostPoolResourceGroupName -Name $VMName
                Write-output "=== Reboot initiated for VM: $VMName"       
            }
        }
        else {
            $shutdown += 1
            Write-output "!! The VM '$VMName' must be started in order to reboot it. !!"       
        }

    }


}