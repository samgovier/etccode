<#
.SYNOPSIS
    This script runs a WMI query against servers to test from the serversToTest variable.
    
.EXAMPLE
    Put this script on an opstools server and create a scheduled task. Get csv results over time.

.NOTES
    File Name       : Measure-WmiTimeTaken.ps1
    Author          : Sam Govier
    Creation Date   : 04/21/2021
#>

# region Config
[CmdletBinding()]
param()

# serversToTest is the list of servers to test WMI against
$serversToTest = @(
)

# endregion Config

# region Execution

# rowToAdd is the csv that will be added to timeTaken.csv after wmi testing
$rowToAdd = "$(Get-Date -Format "yyMMdd HH:mm"),"

# test and measure WMI against each server, then add total seconds to the CSV row
foreach ($server in $serversToTest) {
    $timeTaken = (Measure-Command { Get-WmiObject -List -ComputerName $server -ErrorAction SilentlyContinue }).TotalSeconds
    $rowToAdd += "$server,$timeTaken,"
}

# Write the csv row to the already created timeTaken.csv
Add-Content -Value $rowToAdd -Path "$PSScriptRoot/timeTaken.csv"

# endregion Execution