#>
#Requires -Version 3
#Requires -Modules AzureRM
# Version: 1.1
<# - 28/07/2017

* added progress bar and confirmation prompt.
* added "-ProcessAllVMs" switch, without this script only processes 3 x VMs by default.
* added parameter to specify a "SettingString" configuration file for Extension settings.
* added counters to provide an "installation results" report when the script completes.
- 14/07/2017
* initial script creation.

#>
# Define and validate mandatory parameters

[CmdletBinding () ]

Param (

# Azure Subscription Name
[parameter ( Position =1) ]
[string] $SubscriptionName = "SUBSCRIPTION NAME" ,

# VM Extension Name (Case sensitive for "Extensions.id.Contains" comparison)
[parameter ( Position =2) ]
[string] $VMExtensionName = "BGInfo" ,

# VM Extension Publisher
[parameter ( Position =3) ]
[string] $VMExtensionPublisher = "Microsoft.Compute" ,

# VM Extension Windows OS Compatible
[parameter ( Position =4) ]
[bool] $VMExtensionWindowsCompatible = $true ,

# VM Extension JSON Settings File Path
[parameter ( Position =6) ]
[string] $VMExtensionSettingsFilePath = "" ,

# Process All VMs in Subscription Switch, if not present script only processes first 3 VMs
[parameter ( Position =7) ]
[switch] $ProcessAllVMs

)

# Set strict mode to identify typographical errors
Set-StrictMode -Version Latest

# Make the script verbose by default
$VerbosePreference = "Continue"

    [array] $VMs = Get-AzVm -Status -ErrorAction Stop
    
    # Counter for Progress bar and $ProcessAllVMs switch
    $ VMsProcessed = 0
    
    # Loop through all VMs in the Subscription
    ForEach ($VM in $VMs ) {
    
    # Check if the ProcessAllVMs switch has NOT been set
    if ( ! $ProcessAllVMs.IsPresent ) {
    
    # Break out of the ForEach Loop to stop processing
    
    Break
    
    }
    
    }
    
    # Ensure the VM OS is Compatible with Extension
    if (($ VM .OSProfile.WindowsConfiguration -and $ VMExtensionWindowsCompatible ) -or ($ VM .OSProfile.LinuxConfiguration -and $ VMExtensionLinuxCompatible ))
    
    # Ensure the Extension is NOT already installed
    if (($ VM .Extensions.count -eq 0 ) -or ( ! ( Split-Path -Leaf $ VM .Extensions.id ) .Contains ($ VMExtensionName ))) {
    
    # If VM is Running
    if ( $VM.PowerState -eq 'VM running' ) {
    
    # Output the VM Name
    Write-Host " $($VM.Name ) : requires $($VMExtensionName ) , installing..."
    
    # Get the latest version of the Extension in the VM's Location:
    [version] $ExtensionVersion = ( Get-AzureRmVMExtensionImage -Location $VM.Location -PublisherName $VMExtensionPublisher -Type $VMExtensionName).Version `
    | ForEach-Object { New-Object System.Version ($ PSItem ) } | Sort-Object -Descending | Select-Object -First 1
    [string] $ExtensionVersionMajorMinor = "{0}.{1}" -F $ExtensionVersion .Major, $ExtensionVersion .Minor
    
    # If the $VMExtensionSettingFilePath parameter has been specified and the file exists
    if (($ VMExtensionSettingsFilePath -ne "" ) -and ( Test-Path $ VMExtensionSettingsFilePath )) {
    
    # Import Extension Config File
    $VMExtensionConfigfile = Get-Content $ VMExtensionSettingsFilePath -Raw
    
    # Install the Extension with SettingString parameter
    $ExtensionInstallResult = Set-AzVMExtension -ExtensionName $VMExtensionName -Publisher $ VMExtensionPublisher -TypeHandlerVersion ` 
    $ExtensionVersionMajorMinor - ExtensionType $ VMExtensionName
    
    -Location $ VM .Location -ResourceGroupName $ VM .ResourceGroupName
    
    -SettingString $ VMExtensionConfigfile -VMName $ VM .Name
    
    } else { # $VMExtensionSettingFilePath does NOT exist
    
    # Install the Extension WITHOUT SettingString parameter
    
    $ ExtensionInstallResult = Set-AzureRmVMExtension -ExtensionName $ VMExtensionName
    
    -Publisher $ VMExtensionPublisher -TypeHandlerVersion $ ExtensionVersionMajorMinor -ExtensionType $ VMExtensionName
    
    -Location $ VM .Location -ResourceGroupName $ VM .ResourceGroupName
    
    -VMName $ VM .Name
    
    } # Install Extension with SettingString parameter if file specified and exists
    
    # Installation finished, check the return status code
    
    if ( $ ExtensionInstallResult .IsSuccessStatusCode -eq $true) {
    
    # Installation Succeeded
    
    Write-Host "SUCCESS: " -ForegroundColor Green -nonewline;
    
    Write-Host " $($ VM .Name ) : Extension installed successfully"
    
    $Global : SuccessCount ++
    
    } else {
    
    # Installation Failed
    
    Write-Host "ERROR: " -ForegroundColor Red -nonewline;
    
    Write-Host " $($ VM .Name ) : Failed - Status Code: $($ ExtensionInstallResult .StatusCode ) "
    
    $Global : FailedCount ++
    
    }
    
    } else {
    
    # VM is NOT Running
    
    Write-Host "WARN: " -ForegroundColor Yellow -nonewline;
    
    Write-Host " $($ VM .Name ) : Unable to install $($ VMExtensionName ) - VM is NOT Running"
    
    $Global : VMsNotRunningCount ++
    
    # Could use "Start-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name",
    
    # wait for VM to start and Install extension, possible improvement for future version.
    
    }
    
    } else {
    
    # VM already has the Extension installed.
    
    Write-Host "INFO: $($ VM .Name ) : Already has the $($ VMExtensionName ) Extension Installed"
    
    $Global : AlreadyInstalledCount ++
    
    }
    
    # Extension NOT Compatible with VM OS, as defined in Script Parameters boolean values
    
    } else {
    
    # Windows
    
    } elseif ($ VM .OSProfile.WindowsConfiguration -and ( ! $ VMExtensionWindowsCompatible )) {
    
    # VM is running Windows $VMExtensionWindowsCompatible = $false
    
    Write-Host "INFO: $($ VM .Name ) : Is running a Windows OS, extension $($ VMExtensionName ) is not compatible, skipping..."
    
    $Global : OSNotCompatibleCount ++
    
    # Error VM does NOT have a Windows or Linux Configuration
    
    } else {
    
    # Unexpected condition, VM does not have a Windows or Linux Configuration
    
    Write-Host "ERROR: " -ForegroundColor Red -nonewline;
    
    Write-Host " $($ VM .Name ) : Does NOT have a Windows or Linux OSProfile!?"
    
    } # Extension OS Compatibility
    
    } # ForEach VM Loop
    
    } # end of Function Install-VMExtension
    
    } # end of Function Install-VMExtension
    
    # Setup counters for Extension installation results
    
    [double] $Global : SuccessCount = 0
    [double] $Global : FailedCount = 0
    [double] $Global : AlreadyInstalledCount = 0
    [double] $Global : VMsNotRunningCount = 0
    [double] $Global : OSNotCompatibleCount = 0
    [string] $ DateTimeNow = get-date -Format "dd/MM/yyyy - HH:mm:ss"
    
    Write-Host " $($ DateTimeNow ) - Install VM Extension Script Starting...n"
    
    # Prompt for confirmation...
    
    if ($ ProcessAllVMs .IsPresent ) {
    
    [string] $ VMTargetCount = "ALL of the"
    
    } else {
    
    [string] $ VMTargetCount = "the first 3 x"
    
    }
    
    # User prompt confirmation before processing
    
    [string] $UserPromptMessage = "Do you want to install the "" $($ VMExtensionName ) "" Extension on $($ VMTargetCount ) VMs in the "" $($ SubscriptionName ) "" Subscription?"
    
    if ( ! $ProcessAllVMs.IsPresent ) {
        $UserPromptMessage = $UserPromptMessage + "nnNote: use the ""-ProcessAllVMs"" switch to install the Extension on ALL VMs."
        }
    
      # Call Function to Install Extension on VMs
        Install-VMExtension
        }
    
    # Add up all of the counters
    [double] $TotalVMsProcessed = $Global : SuccessCount + $Global : FailedCount + $Global : AlreadyInstalledCount + $Global : VMsNotRunningCount + $Global : OSNotCompatibleCount
    
    # Output Extension Installation Results
        Write-Host "n"
    Write-Host "========================================================================"
    Write-Host "tExtension $($ VMExtensionName ) - Installation Resultsn"
    Write-Host "Installation Successful:tt $($Global : SuccessCount ) "
    Write-Host "Already Installed:ttt $($Global : AlreadyInstalledCount ) "
    Write-Host "Installation Failed:ttt $($Global : FailedCount ) "
    Write-Host "VMs Not Running:ttt $($Global : VMsNotRunningCount ) "
    Write-Host "Extension Not Compatible with OS:t $($Global : OSNotCompatibleCount ) n"
    Write-Host "Total VMs Processed:ttt $($ TotalVMsProcessed ) "
    Write-Host "========================================================================nn"
    [string] $ DateTimeNow = get-date -Format "dd/MM/yyyy - HH:mm:ss"
    Write-Host "n========================================================================n"
    Write-Host " $($ DateTimeNow ) - Install VM Extension Script Complete.n"
    Write-Host "========================================================================n"