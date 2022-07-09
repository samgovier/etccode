<#
.SYNOPSIS
    This script exports all RDM session data into a custom CSV file.

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`
        
.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.

.PARAMETER CsvExportPath
    CsvExportPath is the path where the CSV export file will be saved.
    It should include the filename: assure that you have access to save to this path.

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    .\Export-EODRDMDataSourceToCsv.ps1 -CsvExportPath C:\users\govier\Desktop\prdexport.csv -DataSourceName mdsn-sqldb-bk

.NOTES
    File Name       : Export-EODRDMDataSourceToCsv.ps1
    Author          : Sam Govier
    Creation Date   : 09/27/21
#>

#region Config

[CmdletBinding()]
param (
    # CsvExportPath is where the CSV export of the datasource is saved. Should include the filename
    [Parameter(Mandatory=$true)]
    [string]
    $CsvExportPath,

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
$exportTestArray = $CsvExportPath.Split('\')
if (-not (Test-Path (($exportTestArray[0..($exportTestArray.length - 2)]) -join '\'))) {
    Write-Error -Message ("The csv export path failed. " +
    "Please check that this path is correct and accessible: $CsvExportPath")
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

    # csvExportArray is the array for exporting the servers + info
    $csvExportArray = @()

    # rdmSessions is an array of all RDM sessions
    $rdmSessions = Get-EODRDMSession

    # progress Numerator and Denominator are used to provide progress info to the CLI
    $progressNumerator = 0
    $progressDenominator = $rdmSessions.Count

    # for each rdm session object, write progress, and add relevant data to the CSV
    foreach ($rdmSession in $rdmSessions) {

        Write-Progress -Activity "Exporting RDM Objects to file..." -PercentComplete ($progressNumerator++ / $progressDenominator * 100)

        $connType = $rdmSession.ConnectionType
        Write-Verbose -Message "Exporting: $($rdmSession.Group)\$($rdmSession.Name)"

        if(($connType) -in @("Group", "SSHShell", "RDPConfigured")) {
            $csvExportArray += New-Object -TypeName PSObject -Property @{
                Name        = $rdmSession.Name
                Type        = $connType
                Group       = $rdmSession.Group
                IP          = $rdmSession.Host
                Icon        = $rdmSession.ImageName
                CredType    = Get-EODRDMSessionCredentialType -RDMSession $rdmSession
                ServerUser  = Get-EODRDMSessionServerUser -RDMSession $rdmSession
                Gateway     = Get-EODRDMSessionGatewayHost -RDMSession $rdmSession
                GatewayCred = Get-EODRDMSessionGatewayCred -RDMSession $rdmSession
            }
        }
        else {
            Write-Warning "Unusual Connection Type Found. Please manually export:`n $($rdmSession.Name)"
        }
    }

    Write-Output -InputObject "Exporting CSV file..."
    $csvExportArray | Select-Object "Name","Type","Group","IP","Icon","CredType","ServerUser","Gateway","GatewayCred" | Export-Csv -UseCulture -Path $CsvExportPath
    Write-Output -InputObject "Exported."
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
    # swap back to the original data source if necessary
    if(-not ($ogDataSource.Name -eq $DataSourceName)) {
        Write-Output -InputObject "Restoring original datasource: $($ogDataSource.Name)"
        Set-EODRDMCurrentDataSource -DataSource $ogDataSource
    }
}

#endregion Execution