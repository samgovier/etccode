<#
.SYNOPSIS
    This script modifies RDM objects using a provided property name and value.

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`
    
.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.

.PARAMETER PropertyName
    PropertyName is the Name of the property to be modified.
    Please dot into values of sub-objects to be modified, eg. RDP.GatewaySelection

.PARAMETER PropertyValue
    PropertyValue is the value that you want to set the property to be.
    It will take any passed type: make sure it matches the required type by RDM.

.PARAMETER TypeToModify
    TypeToModify is an optional filter on the RDM object type.
    It must be from the following set. An empty string covers all objects.
    folder -> "Group", Linux -> "SSHShell", Windows -> "RDPConfigured"

.PARAMETER GroupToModify
    GroupToModify is an optional filter on what folder you want to make changes to.
    RDM uses a Windows-like folder structure with backslashes, eg. prd\tower_c\as\web.

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    .\Set-EODRDMProperty.ps1 -DataSourceName adminuser -PropertyName RDP.GatewaySelection -PropertyValue "SpecificGateway" -TypeToModify "RDPConfigured"

.EXAMPLE
    .\Set-EODRDMProperty.ps1 -DataSourceName ADMIN_mdsn-sqldb-bk -PropertyName Name -PropertyValue "OLD_DONOTUSE" -GroupToModify "prd\common_colt\kafka"

.NOTES
    File Name       : Set-EODRDMProperty.ps1
    Author          : Sam Govier
    Creation Date   : 11/09/21
#>

#region Config

[CmdletBinding()]
param (
    # DataSourceName is the name of the datasource being used in Remote Desktop Manager
    [Parameter(Mandatory=$true)]
    [string]
    $DataSourceName,

    # PropertyName is the Name of the property to change on relevant objects
    [Parameter(Mandatory=$true)]
    [string]
    $PropertyName,

    # PropertyValue is the Value that you want to set the property to be
    [Parameter(Mandatory=$true)]
    $PropertyValue,

    # TypeToModify is the type of object you want to modify. An empty string modifies all objects
    [Parameter(Mandatory=$false)]
    [ValidateSet("Group","RDPConfigured","SSHShell","")]
    $TypeToModify = "",

    # GroupToModify is the group that you would like to modify
    [Parameter(Mandatory=$false)]
    [string]
    $GroupToModify = "",

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

    # GroupsToModify needs to escape the back-slashes
    $GroupToModify = $GroupToModify.Replace("\","\\")

    # serversToModify pulls all RDM sessions, filtering on group and connection type
    $serversToModify = (Get-EODRDMSession | Where-Object -Property Group -match $GroupToModify | Where-Object -Property ConnectionType -match $TypeToModify)

    # progress Numerator and Denominator are used to provide progress info to the CLI
    $progressNumerator = 0
    $progressDenominator = $serversToModify.Count

    # modify the changing property to the new value on each server
    foreach($server in $serversToModify) {

        Write-Progress -Activity "Modifying RDM Objects..." -PercentComplete ($progressNumerator++ / $progressDenominator * 100)
        Write-Verbose "Modifying: $($server.Name)"

        # do some looping to get to the modifying property: propArr splits the property into an array
        $propArr = $PropertyName.Split('.')

        # setObj is gradually set to the modifying property, starts with the server object
        $setObj = $server

        # for each property in the prop array, move setObj to the next property in the tree
        for ($i = 0; $i -lt ($propArr.Count - 1); $i++) {
            $setObj = $setObj.$($propArr[$i])
        }

        # set the final property to the property value
        $setObj.$($propArr[-1]) = $PropertyValue

        # update the session object
        Set-RDMSession -Session $server
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
    Write-Output -InputObject "Updating RDM Application to reflect changes"
    Update-EODRDMUI
    
    # swap back to the original data source if necessary
    if(-not ($ogDataSource.Name -eq $DataSourceName)) {
        Write-Output -InputObject "Restoring original datasource: $($ogDataSource.Name)"
        Set-EODRDMCurrentDataSource -DataSource $ogDataSource
    }
}

#endregion Execution