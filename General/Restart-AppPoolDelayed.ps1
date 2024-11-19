<#
.SYNOPSIS
    Restart-AppPoolDelayed restarts the specified app pool, but with a delay to allow resources to refresh.
    The creation purpose of this script was to install onto the IIS web servers in order to restart the App Pools.
    The script should run as a scheduled task early in the morning every day.

    PREREQ:
    - This script must be run on a server with IIS installed.
    - The script must run in an administrative prompt.

.PARAMETER AppPoolName
    AppPoolName is the name of the app pool to be restarted.

.PARAMETER WaitSeconds
    WaitSeconds is the amount of time to wait after stopping to start. Default is 60 seconds.

.EXAMPLE
    .\Restart-AppPoolDelayed.ps1 -AppPoolName "DefaultAppPool"

.NOTES
    File Name       : Restart-AppPoolDelayed.ps1
    Author          : Sam Govier
    Creation Date   : 09/05/2024
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string]
    $AppPoolName,

    [Parameter(Mandatory=$false)]
    [int]
    $WaitSeconds = 60
)

Write-Output -InputObject "Stopping App Pool $AppPoolName..."
Stop-WebAppPool -Name $AppPoolName

Write-Output -InputObject "Waiting for $WaitSeconds Seconds..."
Start-Sleep -Seconds $WaitSeconds

Write-Output -InputObject "Starting App Pool $AppPoolName..."
Start-WebAppPool -Name $AppPoolName