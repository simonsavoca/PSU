# Script contents
$LabName = 'PSU'
$Environment = @{


    # Network
    Internet = $true
    ExternalSwitch = 'Default Switch'
    AddressSpace = '192.168.11.0/24'

    #General Settings
    EnvironmentPath = "C:\LabEnvironment"
    ToolsPath = "$LabSources\Tools"
    ReferenceDiskSizeInGB = 60
    ReferenceMemorySize = 2GB

    DefaultUsername = 'Administrator'
    DefaultPassword = 'Somepass1'

    RootDomain = 'duckplatform.local'

    DefaultServerOperatingsystem = 'Windows Server 2022 Standard Evaluation (Desktop Experience)'
    DefaultClientOperatingsystem = 'Windows 11 Pro'
}

$LabDefinition = @{
    Name                        = $LabName
    DefaultVirtualizationEngine = 'HyperV'
    VmPath                      = $Environment.EnvironmentPath
    ReferenceDiskSizeInGB       = $Environment.ReferenceDiskSizeInGB
}
# Check Running Lab
If (Get-Lab -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabName }) { Throw "${LabName} already in progress, please use '-Clear' switch first"}
Else { New-LabDefinition @LabDefinition }


$LabInternalNetworkDefinition = @{
    Name         = $LabName
    AddressSpace = $Environment.AddressSpace
}
Add-LabVirtualNetworkDefinition @LabInternalNetworkDefinition

$LabExternalNetworkDefinition = @{
    Name             = $Environment.ExternalSwitch
    HyperVProperties = @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }
}
Add-LabVirtualNetworkDefinition @LabExternalNetworkDefinition

$LabInstallationCredential = @{
    Username = $Environment.DefaultUsername
    Password = $Environment.DefaultPassword
}
Set-LabInstallationCredential @LabInstallationCredential

$LabDomainDefinition = @{
    Name          = $Environment.RootDomain
    AdminUser     = $Environment.DefaultUsername
    AdminPassword = $Environment.DefaultPassword
}
Add-LabDomainDefinition @LabDomainDefinition




# Router for internet
$RouterDefinition = @{
    Name = 'LAB-ROUTER'
    IPAddress = '192.168.11.1'
    Role = Get-LabMachineRoleDefinition -Role Routing
}
$ExternalNetworkAdapterDefinition = New-LabNetworkAdapterDefinition -VirtualSwitch $Environment.ExternalSwitch -UseDhcp -RegisterInDNS $False
$RouterNetworkAdapterDefinition = @()
$RouterNetworkAdapterDefinition += New-LabNetworkAdapterDefinition -VirtualSwitch $LabName -Ipv4Address $RouterDefinition.IPAddress
$RouterNetworkAdapterDefinition += $ExternalNetworkAdapterDefinition


$RouterPostInstallationActivity = @()
$RouterMachineRoleDefinition = @{
    Name                     = $RouterDefinition.Name
    ToolsPath                = $Environment.ToolsPath
    Memory                   = $Environment.ReferenceMemorySize
    OperatingSystem          = $Environment.DefaultServerOperatingsystem
    NetworkAdapter           = $RouterNetworkAdapterDefinition
    Role                     = $RouterDefinition.Role
    PostInstallationActivity = $RouterPostInstallationActivity
}

Add-LabMachineDefinition @RouterMachineRoleDefinition
# Root DC
$RootDCDefinition = @{
    Name = 'T0-DC1'
    IPAddress = '192.168.11.10'
    <#
    DiskName = @(
        Add-LabDiskDefinition -Name 'Data' -DiskSizeInGb 50 -Label "Data" -DriveLetter "E"
        #Add-LabDiskDefinition -Name $SQLDisk -DiskSizeInGb 30 -Label "SQL01" -DriveLetter "F"
    )
    #>
}
$RootDCPostInstallationActivity = @()
#$RootDCPostInstallationActivity += Get-LabPostInstallationActivity -ScriptFileName 'EnableDNSForwardingToRouter.ps1' -DependencyFolder $PSScriptRoot\..\PostInstallationActivities

$RootDCMachineRoleDefinition = @{
    Name                     = $RootDCDefinition.Name
    ToolsPath                = $Environment.ToolsPath
    Memory                   = 4GB
    OperatingSystem          = $Environment.DefaultServerOperatingSystem
    IPAddress                = $RootDCDefinition.IPAddress
    DomainName               = $Environment.RootDomain
    Network                  = $LabName
    Role                     = @(
            Get-LabMachineRoleDefinition -Role RootDC
        )
    PostInstallationActivity = $RootDCPostInstallationActivity
}

Add-LabMachineDefinition @RootDCMachineRoleDefinition

$DomainServerDefinition = @{
    Name = 'T0-SRV1'
    IPAddress = '192.168.11.13'
}
$DomainServerPostInstallationActivity = @()

# Domain Server
$DomainServerMachineRoleDefinition = @{
    Name                     = $DomainServerDefinition.Name
    ToolsPath                = $Environment.ToolsPath
    Memory                   = 4GB
    OperatingSystem          = $Environment.DefaultServerOperatingSystem
    IPAddress                = $DomainServerDefinition.IPAddress
    DomainName               = $Environment.RootDomain
    Network                  = $LabName
    PostInstallationActivity = $DomainServerPostInstallationActivity
}
Add-LabMachineDefinition @DomainServerMachineRoleDefinition


Install-Lab -NetworkSwitches -BaseImages -VMs
# Build by role in order to work properly
Install-Lab -Routing
#Install-Lab -Domains

# Don't forget to build others VMs without roles
#Install-Lab -StartRemainingMachines -PostInstallations