<#
.SYNOPSIS
    This script pulls the health details on objects on a specific Dell Storage Manager host
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

.PARAMETER ScSerialNumber
    ScSerialNumber is the Storage Center Serial Number. -1 represents any/all.

.EXAMPLE
    With this file and the EOD.Dell.Common folder in the \EXEXML\ folder on the PRTG parent probe server,
    Create an xmlexe sensor that calls this script, and pass the following parameters:
    -Hostname "<Hostname-of-your-SC-Manager-server>" -Username "<Username-to-login-with>" -PathToDellCommon "<path>"
    Eg. -Hostname "ma-sc-manag-01" -Username "Admin"
        -PathToDellCommon "D:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\EOD.Dell.Common\EOD.Dell.Common.psd1"

.NOTES
    File Name       : EOD_DellHealth.ps1
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

    # pull unhealthy objects
    $unhealthyDisks = Get-EODDellUnhealthyDisks -DellApiCon $dellConn -ScSerialNumber $ScSerialNumber
    $unhealthyVolumes = Get-EODDellUnhealthyVolumes -DellApiCon $dellConn -ScSerialNumber $ScSerialNumber
    $unhealthyCont = Get-EODDellUnhealthyCont -DellApiCon $dellConn -ScSerialNumber $ScSerialNumber
    $unhealthyPower = Get-EODDellUnhealthyPower -DellApiCon $dellConn -ScSerialNumber $ScSerialNumber
    $unhealthyObj = $unhealthyDisks + $unhealthyVolumes + $unhealthyCont + $unhealthyPower

    # output a channel for number of unhealthy objects
    $XMLOutput += Add-EODDellPRTGChannel -ChannelName "# of Unhealthy Disks" -ChannelValue $unhealthyDisks.Length -CustomUnit "Disks"
    $XMLOutput += Add-EODDellPRTGChannel -ChannelName "# of Unhealthy Volumes" -ChannelValue $unhealthyVolumes.Length -CustomUnit "Volumes"
    $XMLOutput += Add-EODDellPRTGChannel -ChannelName "# of Unhealthy Controllers" -ChannelValue $unhealthyCont.Length -CustomUnit "Controllers"
    $XMLOutput += Add-EODDellPRTGChannel -ChannelName "# of Unhealthy Power Supplies" -ChannelValue $unhealthyPower.Length -CustomUnit "Power Supplies"

    # if there are unhealthy disks, list them: otherwise all are healthy
    if ($unhealthyObj.Length -gt 0) {
        $chanMes = "The following objects have a non-healthy status: $($unhealthyObj -join ", ")"
    }
    else {
        $chanMes = "All Objects Healthy"
    }

    # Add the channel message to the output XML
    $XmlOutput += "<Text>$chanMes</Text>`r`n"
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