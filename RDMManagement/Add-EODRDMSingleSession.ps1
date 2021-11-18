<#
.SYNOPSIS
    This script adds a single RDM session object to the RDM database, folder or machine.

    For more than one session, it is recommended that you use the import script instead, Import-EODRDMDataSourceFromCsv.ps1

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`
    
.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.

.PARAMETER SessionName
    SessionName is the name of the item you're adding: folder name, or hostname of the new machine.

.PARAMETER Type
    Type is the type of RDM session object:
    folder -> "Group", Linux -> "SSHShell", Windows -> "RDPConfigured"

.PARAMETER Group
    Group is the folder path where you want the object to be placed.
    RDM uses a Windows-like folder structure with backslashes, eg. prd\tower_c\as\web.
    A new folder should be placed in it's own group, eg. tower_k goes in prd\tower_k.

.PARAMETER Icon
    Icon is the image and color used for the object.
    Generally, this should just match the folder color, eg. "[Green]" for Tower C.
    See the wiki on how to configure custom icons.

.PARAMETER IP
    IP is the IP Address of the object you are adding, required for new machines.

.PARAMETER Gateway
    Gateway is the gateway host used to connect to the production environment.
    The parameter is optional; if not provided, defaults of ssh. or rds.eodops.com will be used.

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    ./Add-EODRDMSingleSession.ps1 -DataSourceName "ADMIN_mdsn-sqldb-bk" -SessionName "MA-ASC-HV99" -Type "RDPConfigured" -Group "prd\tower_c\as\web" -Icon "[Green]" -IP "1.2.3.4" -Gateway "rds.eodops.com"

.NOTES
    File Name       : Add-EODRDMSingleSession.ps1
    Author          : Sam Govier
    Creation Date   : 10/25/21
#>

#region Config

[CmdletBinding()]
param (
    # DataSourceName is the name of the datasource being used in Remote Desktop Manager
    [Parameter(Mandatory=$true)]
    [string]
    $DataSourceName,

    # SessionName is the name of the server or folder to be added
    [Parameter(Mandatory=$true)]
    [string]
    $SessionName,

    # Type is the type of object to be added: folder, RDP, or SSH
    [Parameter(Mandatory=$true)]
    [ValidateSet("Group","RDPConfigured","SSHShell")]
    $Type,

    # Group is the folder that the object goes in, eg. prd\tower_c\as\web
    [Parameter(Mandatory=$true)]
    [string]
    $Group,

    # Icon is the icon used in RDM for the object, or just color on default icon
    [Parameter(Mandatory=$true)]
    [string]
    $Icon,

    # IP is the IP address of the machine being added, if it's a machine
    [Parameter(Mandatory=$false)]
    [string]
    $IP = "",

    # Gateway is the host used to jump to the Prod environment, eg. ssh.eodops.com
    [Parameter(Mandatory=$false)]
    [string]
    $Gateway = "",

    # PathToRDMCommon is the path to the RDM Powershell Module
    [Parameter(Mandatory=$false)]
    [string]
    $PathToRDMCommon = "$PSScriptRoot\EOD.RDM.Common\EOD.RDM.Common.psd1"
)

#endregion Config

#region Functions

 <#
 .SYNOPSIS
    Import-EODRDMModule attempts to import EOD.RDM.Common, catching various errors,
    and returning true if successful.
 #>
function Import-EODRDMModule {
    [CmdletBinding()]
    param ()
    try {
        Import-Module -Name $PathToRDMCommon -ErrorAction Stop -Global
    }

    # FileNotFound is thrown if we can't access the direct module file
    catch [System.IO.FileNotFoundException] {
        Write-Warning -Message ("The RDM EOD Module could not be found. " +
            "Please ensure that EOD.RDM.Common.psd1 is reachable by the script.")
        throw $PSItem
    }

    # InvalidOperation is thrown if the sub-module (ie. RDM module) fails
    catch [System.Management.Automation.PSInvalidOperationException] {
        Write-Warning -Message ("The RDM PowerShell Module couldn't be found.`n" +
            "Install via an elevated PowerShell prompt: ``Install-Module RemoteDesktopManager``")
        throw $PSItem
    }
}

#endregion Functions

#region Execution

# import the EOD Remote Desktop Manager module
Import-EODRDMModule -ErrorAction Stop

# get current data source
$ogDataSource = Get-EODRDMCurrentDataSource

try {
    # if the data source isn't currently connected, connect
    if(-not ($ogDataSource.Name -eq $DataSourceName)) {
        Write-Output -InputObject "Swapping data source to: $DataSourceName"
        Get-EODRDMDataSource -Name $DataSourceName | Set-EODRDMCurrentDataSource
    }

    if($Type -ne "Group") {
        if([string]::IsNullOrWhiteSpace($IP)) {

            Write-Error ("No IP specified. " +
            "An IP address is required for machine additions.")

            return
        }
        if([string]::IsNullOrWhiteSpace($Gateway)) {

            $Gateway = Get-EODRDMDefaultGateway -Type $Type

            Write-Warning "No Gateway specified. Using default: $Gateway"
        }
    }

    try {
        Write-Output -InputObject "Creating: $Group\$SessionName"
        Add-EODRDMSession -Name $SessionName -Type $Type -Group $Group -IP $IP -CredType "Inherited" -Icon $Icon -Gateway $Gateway -WarningAction Stop
    }
    catch [System.Management.Automation.ActionPreferenceStopException] {
        Write-Warning ("Unable to save session, Access is Denied. " +
        "Please use a DataSource connection with administrative privileges.")
        return
    }
}
catch [System.Management.Automation.ValidationMetadataException] {
    Write-Warning -Message ("The DataSource '$DataSourceName' could not be found. " +
    "Specify the correct datasource or configure the desired one in RDM directly.")
    throw $PSItem
}
catch {
    throw $PSItem
}
finally {
    # update RDM UI
    Write-Output -InputObject "Updating RDM Application to reflect new object"
    Update-EODRDMUI

    # swap back to the original data source if necessary
    if(-not ($ogDataSource.Name -eq $DataSourceName)) {
        Write-Output -InputObject "Restoring original datasource: $($ogDataSource.Name)"
        Set-EODRDMCurrentDataSource -DataSource $ogDataSource
    }
}

#endregion Execution