<#
.SYNOPSIS
    TODO

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`

.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    ./EODRDMTemplate.ps1

.NOTES
    File Name       : 
    Author          : 
    Creation Date   : 
#>

#region Config

[CmdletBinding()]
param (
    # DataSourceName is the name of the datasource being used in Remote Desktop Manager
    [Parameter(Mandatory=$true)]
    [string]
    $DataSourceName,

    # FolderPath is the path to the objects whose color needs to be set
    [Parameter(Mandatory=$true)]
    [string]
    $FolderPath,

    # ColorToSet is the color to set on the object and its child items
    [Parameter(Mandatory=$false)]
    [string]
    $ColorToSet,

    # PathToRDMCommon is the path to the RDM Powershell Module
    [Parameter(Mandatory=$false)]
    [string]
    $PathToRDMCommon = "$PSScriptRoot\EOD.RDM.Common\EOD.RDM.Common.psd1"
)

# Clean FolderPath to make it useful for querying for objects
$queryPath = $FolderPath.Replace('/','\').TrimStart('\').ToLower()
if (-not $queryPath.EndsWith('\')) {
    $queryPath = $queryPath + '\'
}

# Set Color to Title Case to match RDM casing
$ColorToSet = (Get-Culture).TextInfo.ToTitleCase($ColorToSet)

# Possible Colors allowed- check and fail if not in this collection
$COLORS      = @{"Black" = "[Black]"; "Red" = "[Red]"; "Blue" = "[Blue]";
"Orange" = "[Orange]"; "Yellow" = "[Yellow]" ; "Purple" = "[Purple]"; "Green" = "[Green]"; "Forest" = "[Forest]"}

if ((-not [string]::IsNullOrWhiteSpace($ColorToSet)) -and ($COLORS.keys -notcontains $ColorToSet)) {
    Write-Error -Message "The color '$ColorToSet' is not allowed in the EOD RDM Database. Please use an allowed color: $($COLORS.keys -join ", ")"
    return
}

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
        Import-Module -Name $PathToRDMCommon -ErrorAction Stop -Global -Force
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

    # folderObject is the RDM object representing the folder that's being changed
    $folderObject = Get-EODRDMSingleGroupObj -FullGroupPath $queryPath

    # childObjects is all objects under the chosen folder
    $childObjects = Get-EODRDMChildSessions -FullGroupPath $queryPath

    # if there is no explicit color set, pull the color from the parent folder
    if([string]::IsNullOrWhitespace($ColorToSet)) {
        $parentFolderObj = Get-EODRDMSingleGroupObj -FullGroupPath ($queryPath.Substring(0,$queryPath.TrimEnd('\').LastIndexOf('\')))
        $ColorToSet = Get-EODRDMSessionColor -RDMSession $parentFolderObj
    }

    # set the color on the folder itself
    Set-EODRDMSessionColor -RDMSession $folderObject -Color $ColorToSet
    Set-EODRDMSession -Session $folderObject

    # set the color on all child objects
    foreach($childObj in $childObjects) {
        if ($null -ne $childObj) {
            Set-EODRDMSessionColor -RDMSession $childObj -Color $ColorToSet
            Set-EODRDMSession -Session $childObj
        }
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