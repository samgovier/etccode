<#
.SYNOPSIS
    This is a wrapper script to allow using Test-NetConnection in PRTG (particularly from different devices, like a VPN endpoint).

.PARAMETER Target
    Target is the IP or DNS address of the device that you want to send a test connection.

.PARAMETER Port
    Port is the optional parameter specifying the port that you want to test (via TCP).
    This is a hard test: if the TCP test fails, a 1 (error) is returned, even if a ping would succeed.

.PARAMETER Legacy
    Legacy is a switch to do a simple ping using the simpler Test-Connection command, where Test-NetConnection doesn't exist (eg. Windows 2008 R2)
    Pinging by port is not supported on legacy.

.EXAMPLE
    With this file in the \EXEXML\ folder on the PRTG parent probe server,
    Create an xmlexe sensor that calls this script, and pass the following parameters:
    -Target "<Host-or-IP-Address>" [-Port <optional-port-as-integer>]
    Eg. -Target 195.68.23.37 -Port 443
    Eg. -Target "ma-c-prtg01"

.NOTES
    File Name       : EOD_Test-NetConnection.ps1
    Author          : Sam Govier
    Creation Date   : 04/06/2021
#>

# region Config

[CmdletBinding()]
param (
    # Target is the IP or DNS address of the device you want to test
    [Parameter(Mandatory=$true)]
    [string]
    $Target,

    # Port is the optional specification of the port to test
    [Parameter(Mandatory=$false)]
    [int]
    $Port,

    # Legacy is an optional switch to use Test-Connection instead of -NetConnection
    [Parameter(Mandatory=$false)]
    [switch]
    $Legacy
)

# endregion Config

# region Execution

try {
    # XMLOutput is the XML output, done in the format PRTG will use to ingest data. Start with the opening tag
    $XMLOutput = "<prtg>`r`n"

    # Depending on the provided parameters, perform a connection test
    if ($Legacy) {
        $TestResult = Test-Connection $Target -Quiet
    }
    elseif ($Port -gt 0) {
        $TestResult = Test-NetConnection $Target -Port $Port -InformationLevel Quiet
    }
    else {
        $TestResult = Test-NetConnection $Target -InformationLevel Quiet
    }

    # if the above TestResult succeeds, return success: otherwise return error
    if ($TestResult) {
        $XMLOutput += "<text>Connection test succeeded.</text>`r`n"

        # Additional Info PRTG demands
        $XMLOutput += "<result>`r`n"
        $XMLOutput += "<channel>Ping Result</channel>`r`n"
        $XMLOutput += "<value>1</value>`r`n"
        $XMLOutput += "</result>`r`n"
    }
    else {
        $XMLOutput += "<error>1</error>`r`n"
        $XMLOutput += "<text>Connection test failed.</text>`r`n"
    }
}
catch {
    # Unexpected failure, write to XML and exit
    $XMLOutput += "<error>1</error>`r`n"
    $XMLOutput += "<text>**Connection Error. Investigate Script.** | $($PSItem.Exception)</text>`r`n"
}

# Finally add the closing tag
$XMLOutput += "</prtg>`r`n"

# Write the XML output
Write-Output -InputObject $XMLOutput

# endregion Execution