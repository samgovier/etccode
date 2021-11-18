<#
.SYNOPSIS
    This script imports RDM session data from a custom CSV file.

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`
        
.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.

.PARAMETER CsvImportPath
    CsvImportPath is the path to the CSV import file that will be imported from.
    Ensure that the file is accessible and you have permissions to read it.
    If you are making your own CSV, use the wiki to ensure it is formatted correctly.

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    .\Import-EODRDMDataSourceFromCsv.ps1 -CsvImportPath C:\users\govier\desktop\newmachines.csv -DataSourceName adminuser

.NOTES
    File Name       : Import-EODRDMDataSourceFromCsv.ps1
    Author          : Sam Govier
    Creation Date   : 09/28/21
#>

#region Config

[CmdletBinding()]
param (
    # CsvImportPath is the path to the CSV being imported. Should include the filename
    [Parameter(Mandatory=$true)]
    [string]
    $CsvImportPath,

    # DataSourceName is the name of the datasource being used in Remote Desktop Manager
    [Parameter(Mandatory=$true)]
    [string]
    $DataSourceName,

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

# test csv path and exit if failure
if (-not (Test-Path $CsvImportPath)) {
    Write-Error -Message ("The csv import path failed. " +
    "Please check that this path is correct and accessible: $CsvImportPath")
    return
}

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
    
    try {
        # get current rdmSessions for comparison
        Write-Verbose "Attempting to pull any existing RDM session objects"
        $rdmSessions = Get-EODRDMSession -ErrorAction Stop
    }
    catch {
        # if no sessions, just return empty array
        $rdmSessions = @()
    }

    # csvImport is the Imported csv object, as an arraylist for flexibility
    $csvImport = [System.Collections.ArrayList](Import-Csv -Path $CsvImportPath -UseCulture)

    # groups is the csvImport filtered to groups, as an arraylist for flexibility
    $groups = [System.Collections.ArrayList]($csvImport | Where-Object -Property Type -eq "Group")

    # folderLevel keeps track of folder level, so that folder import flows from the root out
    $folderLevel = 0

    # progress Numerator and Denominator are used to provide progress info to the CLI
    $progressNumerator = 0
    $progressDenominator = $csvImport.Count

    # while we still have groups to import
    while ($groups.Count -gt 0) {

        # find what folder level is next to import
        $curGroups = $groups | Where-Object -FilterScript { ($PSItem.Group.ToCharArray() | Where-Object { $PSItem -eq '\' } | Measure-Object).Count -eq $folderLevel }

        # for each of these groups, write progress, skip if needed, otherwise import
        foreach($group in $curGroups) {

            Write-Progress -Activity "Importing RDM objects to $DataSourceName" -PercentComplete ($progressNumerator++ / $progressDenominator * 100)

            if(($rdmSessions | Where-Object -Property Name -eq $group.Name | Where-Object -Property Group -eq $group.Group).Count -gt 0) {
                Write-Warning "$($group.Group) already exists. Skipping."
            }
            else {
                try {
                    Write-Verbose -Message "Creating: $($group.Group)"
                    Add-EODRDMSession -Name $group.Name -Type $group.Type -Group $group.Group -IP $group.IP -CredType $group.Creds -Icon $group.Icon -Gateway "" -WarningAction Stop
                }
                catch [System.Management.Automation.ActionPreferenceStopException] {
                    Write-Warning ("Unable to save session, Access is Denied. " +
                        "Please use a DataSource connection with administrative privileges.")
                    return
                }
            }

            # remove imported groups
            $csvImport.Remove($group)
            $groups.Remove($group)
        }

        # go to the next folder level down
        $folderLevel++
    }

    # all remaining sessions are machines: skip if needed, otherwise import
    foreach($session in $csvImport) {

        Write-Progress -Activity "Importing RDM objects to $DataSourceName" -PercentComplete ($progressNumerator++ / $progressDenominator * 100)

        if(($rdmSessions | Where-Object -Property Name -eq $session.Name).Count -gt 0) {
            Write-Warning "$($session.Name) already exists. Skipping."
            continue
        }

        Write-Verbose -Message "Creating: $($session.Group)\$($session.Name)"
        Add-EODRDMSession -Name $session.Name -Type $session.Type -Group $session.Group -IP $session.IP -CredType $session.Creds -Icon $session.Icon -Gateway $session.Gateway
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