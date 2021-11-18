<#
.SYNOPSIS
    This script pulls latency and IOPS details about all Volumes and Tiers on a specific Dell Storage Manager host
    and outputs that data using the PRTG XML formatting.

.PARAMETER Username
    Username is username for the connection to Dell Storage Manager. Password config is above.

    HOW TO CONFIGURE PASSWORD:
    On the PRTG parent, you must run "EOD.Dell.Common/Set-PasswordForStorageDevice.ps1"
    as the user who runs the script (eg. PRTG Service Account). This allows us to store
    a user-specific password hash that is encrypted and useless to other users.

.PARAMETER Hostname
    Hostname is the Dell Storage Manager host to connect to

.PARAMETER PathToDellCommon
    PathToDellCommon is the path to the EOD.Dell.Common manifest on the PRTG parent
    THIS SHOULD BE USED IN MOST CASES. A full path is required for Win Server 2008 R2.

.PARAMETER IOPSMode
    IOPSMode is a switch to run the script and output IOPS instead of time

.PARAMETER ScSerialNumber
    ScSerialNumber is the Storage Center Serial Number. -1 represents any/all.

.EXAMPLE
    With this file and the EOD.Dell.Common folder in the \EXEXML\ folder on the PRTG parent probe server,
    Create an xmlexe sensor that calls this script, and pass the following parameters:
    -Hostname "<Hostname-of-your-SC-Manager-server>" -Username "<Username-to-login-with>" -PathToDellCommon "<path>"
    Eg. -Hostname "ma-sc-manag-01" -Username "Admin"
        -PathToDellCommon "D:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\EOD.Dell.Common\EOD.Dell.Common.psd1"

.NOTES
    File Name       : EOD_DellLatency.ps1
    Author          : Sam Govier
    Creation Date   : 12/07/20
#>

#region Config

[CmdletBinding()]
param (
    # Username is the username for the connection to Dell Storage Manager
    [Parameter(Mandatory=$true)]
    [string]
    $Username,

    # Hostname is the Dell Storage Manager host to connect to
    [Parameter(Mandatory=$true)]
    [string]
    $Hostname,

    # PathToDellCommon is the path to the EOD.Dell.Common manifest on the PRTG parent
    [Parameter(Mandatory=$false)]
    $PathToDellCommon = ".\EOD.Dell.Common\EOD.Dell.Common.psd1",

    # IOPSMode is a switch to run the script and output IOPS instead of time
    [Parameter(Mandatory=$false)]
    [switch]
    $IOPSMode,

    # ScSerialNumber is the Storage Center Serial Number. -1 represents any/all.
    [Parameter(Mandatory=$false)]
    [long]
    $ScSerialNumber = -1
)

# Import the common module with all of the useful EOD Dell functions
Import-Module -Name $PathToDellCommon

#endregion Config

#region Execution
try {
    # XMLOutput is the XML output, done in the format PRTG will use to ingest data. Start with the opening tag
    $XMLOutput = "<prtg>`r`n"

    # dellConn is the open connection to the Dell Storage Manager
    $dellConn = Connect-EODDellScConnection -Username $Username -Hostname $Hostname

    # Pull volume io data en masse and write either IOPS channels or Latency channels
    Get-EODDellVolumeIoData -DellApiConn $dellConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        if ($IOPSMode) {
            $XMLOutput += Add-EODDellPRTGChannel -ChannelName "Volume $($PSItem.InstanceName) Read IOPS" -ChannelValue $PSItem.ReadIops -CustomUnit "IO/s"
            $XMLOutput += Add-EODDellPRTGChannel -ChannelName "Volume $($PSItem.InstanceName) Write IOPS" -ChannelValue $PSItem.WriteIops -CustomUnit "IO/s"
        }
        else {
            $XMLOutput += Add-EODDellPRTGChannel -ChannelName "Volume $($PSItem.InstanceName) Read Latency" -ChannelValue (ConvertTo-MsFromMicro -MicroVal $PSItem.ReadLatency) -CustomUnit "ms" -Float
            $XMLOutput += Add-EODDellPRTGChannel -ChannelName "Volume $($PSItem.InstanceName) Write Latency" -ChannelValue (ConvertTo-MsFromMicro -MicroVal $PSItem.WriteLatency) -CustomUnit "ms" -Float
        }
    }
}
catch {
    # ErrorMessage is the message that will be returned to the PRTG server
    $ErrorMessage = ""

    # Known error: this is thrown in cases of latency
    if ($PSItem.Exception -match "StorageCenterError - Error Getting Historical Volume IO Usage:") {
        $ErrorMessage += "**Historical IO inaccesible. Connection may be timing out: investigate $Hostname** | "
    }

    # Add the caught exception and insert the formatted Error XML
    $ErrorMessage += $PSItem.Exception
    $XMLOutput += Add-EODDellPRTGError -ErrorMessage $ErrorMessage
}

# Finally add the closing tag
$XMLOutput += "</prtg>`r`n"

# Gracefully close the Dell Storage Manager connection
Disconnect-EODDellScConnection -DellApiConn $dellConn

# Write the XML output
Write-Output -InputObject $XMLOutput

#endregion Execution