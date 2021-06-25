# Input bindings are passed in via param block.
param($Timer)

<#
    Requirements:
    WVD Host Pool must be set to Depth First
    An Azure Function App
        Use System Assigned Managed ID
        Give contributor rights for the Session Host VM Resource Group to the Managed ID
   The script requires the following PowerShell Modules and are included in PowerShell Functions by default
        az.compute 
        az.desktopvirtualization
    For best results set a GPO to log out disconnected and idle sessions
.NOTES
#>

######## Variables ##########
$VerbosePreference = "Continue"
$serverStartThreshold = 2

$usePeak = "yes"
$peakServerStartThreshold = 4
$startPeakTime = '08:00:00'
$endPeakTime = '18:00:00'
$timeZone = "W. Europe Standard Time"
$peakDay = 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'

$hostPoolName = 'GSV-DEFAULT-POOL'
$hostPoolRg = 'GSV-WVD'
$sessionHostVmRg= 'GSV-WVD'
$domainName = 'intern.stichtsevecht.nl'

############## Functions ####################

Function Start-SessionHost {
    param (
        $sessionHosts,
        $hostsToStart
    )

    # Number of off session hosts accepting connections
    $offSessionHosts = $sessionHosts | Where-Object { $_.Status -eq "Unavailable" -or $_.Status -eq "Shutdown" }
    $offSessionHostsCount = $offSessionHosts.count
    Write-Verbose "Off Session Hosts $offSessionHostsCount"
    Write-Verbose ($offSessionHosts | Out-String)

    if ($offSessionHosts.Count -eq 0 ) {
        Write-Error "Start threshold met, but there are no hosts available to start"
    }
    else {
        if ($hostsToStart -gt $offSessionHostsCount) {
            $hostsToStart = $offSessionHostsCount
        }
        Write-Verbose "Conditions met to start a host"
        $counter = 0
        while ($counter -lt $hostsToStart) {
            $startServerName = ($offSessionHosts | Select-Object -Index $counter).name
            Write-Verbose "Server to start $startServerName"
            try {
                # Start the VM
                $vmName = ($startServerName -split { $_ -eq '.' -or $_ -eq '/' })[1]
                Start-AzVM -ErrorAction Stop -ResourceGroupName $sessionHostVmRg -Name $vmName
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error ("Error starting the session host: " + $ErrorMessage)
                Break
            }
            $counter++
        }
    }
}

function Stop-SessionHost {
    param (
        $SessionHosts,
        $hostsToStop
    )
    # Get computers running with no users
    $emptyHosts = $sessionHosts | Where-Object { $_.Session -eq 0 -and $_.Status -eq 'Available' }
    $emptyHostsCount = $emptyHosts.count
    Write-Verbose "Evaluating servers to shut down"

    if ($emptyHostsCount -eq 0) {
        Write-error "No hosts available to shut down"
    }
    else { 
        if ($hostsToStop -ge $emptyHostsCount) {
            $hostsToStop = $emptyHostsCount
        }
        Write-Verbose "Conditions met to stop a host"
        $counter = 0
        while ($counter -lt $hostsToStop) {
            $shutServerName = ($emptyHosts | Select-Object -Index $counter).Name 
            Write-Verbose "Shutting down server $shutServerName"
            try {
                # Stop the VM
                $vmName = ($shutServerName -split { $_ -eq '.' -or $_ -eq '/' })[1]
                Stop-AzVM -ErrorAction Stop -ResourceGroupName $sessionHostVmRg -Name $vmName -Force
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error ("Error stopping the VM: " + $ErrorMessage)
                Break
            }
            $counter++
        }
    }
}   

########## Script Execution ##########

# Get Host Pool 
try {
    $hostPool = Get-AzWvdHostPool -ResourceGroupName $hostPoolRg -Name $hostPoolName 
    Write-Verbose "HostPool:"
    Write-Verbose $hostPool.Name
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error getting host pool details: " + $ErrorMessage)
    Break
}

# Verify load balancing is set to Depth-first
if ($hostPool.LoadBalancerType -ne "DepthFirst") {
    Write-Error "Host pool not set to Depth-First load balancing.  This script requires Depth-First load balancing to execute"
    exit
}

# Check if peak time and adjust threshold
# Warning! will not adjust for DST
if ($usePeak -eq "yes") {
    $utcDate = ((get-date).ToUniversalTime())
    $tZ = Get-TimeZone $timeZone
    $date = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDate, $tZ)
    write-verbose "Date and Time"
    write-verbose $date
    $utcOffset = $tz.BaseUtcOffset.TotalHours
    $dateDay = (((get-date).ToUniversalTime()).AddHours($utcOffset)).dayofweek
    Write-Verbose $dateDay
    $startPeakTime = get-date $startPeakTime
    $endPeakTime = get-date $endPeakTime
    if ($date -gt $startPeakTime -and $date -lt $endPeakTime -and $dateDay -in $peakDay) {
        Write-Verbose "Adjusting threshold for peak hours"
        $serverStartThreshold = $peakServerStartThreshold
    } 
}

# Get the Max Session Limit on the host pool
# This is the total number of sessions per session host
$maxSession = $hostPool.MaxSessionLimit
Write-Verbose "MaxSession:"
Write-Verbose $maxSession

# Find the total number of session hosts
# Exclude servers in drain mode/ created today and do not allow new connections
$logs = Get-AzLog -ResourceProvider Microsoft.Compute -StartTime (Get-Date).Date
$VMs = @()
  foreach($log in $logs)
  {
    if(($log.OperationName.Value -eq 'Microsoft.Compute/virtualMachines/write') -and ($log.SubStatus.Value -eq 'Created'))
    {
    Write-Output "- Found VM creation at $($log.EventTimestamp) for VM $($log.Id.split("/")[8]) in Resource Group $($log.ResourceGroupName) found in Azure logs"
    $VMs += $hostPool.Name + "/" + $($log.Id.split("/")[8]) +".$DomainName"
  }
}

start-sleep 5

try {
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $hostPoolRg -HostPoolName $hostPoolName | Where-Object { $_.AllowNewSession -eq $true -and $_.Name -notin $VMs }
    # Get current active user sessions
    $currentSessions = 0
    foreach ($sessionHost in $sessionHosts) {
        $count = $sessionHost.session
        $currentSessions += $count
    }
    Write-Verbose "CurrentSessions"
    Write-Verbose $currentSessions
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error getting session hosts details: " + $ErrorMessage)
    Break
}

# Number of running and available session hosts
# Host shut down are excluded
$runningSessionHosts = $sessionHosts | Where-Object { $_.Status -eq "Available" }
$runningSessionHostsCount = $runningSessionHosts.count
Write-Verbose "Running Session Host $runningSessionHostsCount"
Write-Verbose ($runningSessionHosts | Out-string)

# Target number of servers required running based on active sessions, Threshold and maximum sessions per host
$sessionHostTarget = [math]::Ceiling((($currentSessions + $serverStartThreshold) / $maxSession))

if ($runningSessionHostsCount -lt $sessionHostTarget) {
    Write-Verbose "Running session host count $runningSessionHosts is less than session host target count $sessionHostTarget, run start function"
    $hostsToStart = ($sessionHostTarget - $runningSessionHostsCount)
    Start-SessionHost -sessionHosts $sessionHosts -hostsToStart $hostsToStart
}
elseif ($runningSessionHostsCount -gt $sessionHostTarget) {
    Write-Verbose "Running session hosts count $runningSessionHostsCount is greater than session host target count $sessionHostTarget, run stop function"
    $hostsToStop = ($runningSessionHostsCount - $sessionHostTarget)
    Stop-SessionHost -SessionHosts $sessionHosts -hostsToStop $hostsToStop
}
else {
    Write-Verbose "Running session host count $runningSessionHostsCount matches session host target count $sessionHostTarget, doing nothing"
}