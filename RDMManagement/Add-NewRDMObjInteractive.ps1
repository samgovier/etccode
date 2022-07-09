<#
.SYNOPSIS
    This script provides interactive prompts to help a user add a single RDM session to a RDM database.

    For more than one session, it is recommended that you use the import script instead, Import-EODRDMDataSourceFromCsv.ps1

    For this script to work properly, assure you have RDM version 2021.2 or newer installed.
    You also need to install the RDM PowerShell module before running the script.
    Install via an elevated PowerShell prompt: `Install-Module RemoteDesktopManager`
    
.PARAMETER DataSourceName
    DataSourceName is the name of the datasource in Remote Desktop Manager to interface with.
    The default is the standard ADMIN_mdsn-sqldb-bk

.PARAMETER PathToRDMCommon
    PathToRDMCommon is the path to the EOD.RDM.Common manifest in the RDM Powershell Pack.
    The default is the EOD.RDM.Common subfolder, which should be under this script.

.EXAMPLE
    ./Add-NewRDMObjInteractive.ps1

.NOTES
    File Name       : Add-NewRDMObjInteractive.ps1
    Author          : Sam Govier
    Creation Date   : 06/29/22
#>

#region Config

[CmdletBinding()]
param (
    # DataSourceName is the name of the datasource being used in Remote Desktop Manager
    [Parameter(Mandatory=$false)]
    [string]
    $DataSourceName = "ADMIN_mdsn-sqldb-bk",

    # PathToRDMCommon is the path to the RDM Powershell Module
    [Parameter(Mandatory=$false)]
    [string]
    $PathToRDMCommon = "$PSScriptRoot\EOD.RDM.Common\EOD.RDM.Common.psd1"
)

# The following variables are used for display formatting for the interactive parts of the script
$H1 = "=============================="
$H2 = "---------------------"
$CR = "`r`n"
$FOOT = "$CR$H2$CR"
$2CR = "$CR$CR"

# The following variables are used to map user-understood values to RDM-understood attributes
$OBJ_TYPES   = @{"RDP" = "RDPConfigured"; "SSH" = "SSHShell"; "FOLDER" = "Group"}
$COLORS      = @{"Black" = "[Black]"; "Red" = "[Red]"; "Blue" = "[Blue]";
"Orange" = "[Orange]"; "Yellow" = "[Yellow]" ; "Purple" = "[Purple]"; "Green" = "[Green]"; "Forest" = "[Forest]"}
$CRED_TYPES  = @{"Inherited" = "Inherited"; "Custom" = "SessionSpecific"; "User Vault" = "PrivateVaultSearch"}

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

<#
.SYNOPSIS
    Invoke-PromptWhileNull is a function to run a command over-and-over until the result isn't null
#>
function Invoke-PromptWhileNull {
    [CmdletBinding()]
    param (
        # PromptCommand is the command to run; it should return true or false to use for looping
        [Parameter(Mandatory=$true)]
        $PromptCommand
    )

    # Run the command, and re-run it if the result is null, otherwise return
    do {
        $result = Invoke-Command -ScriptBlock $PromptCommand
    }
    while($null -eq $result)

    return $result
}

<#
.SYNOPSIS
    Get-ObjType prompts the user for the RDM object type, and returns null if the type isn't valid
#>
function Get-ObjType {

    # Prompt for object type with options
    $objType = (Read-Host -Prompt "$($CR)INPUTS:$($CR)Object Type$CR($($OBJ_TYPES.keys -join ", "))$FOOT").Trim().ToUpper()

    # If the type isn't valid, return null
    if($OBJ_TYPES.keys -notcontains $objType) {
        Write-Warning -Message "Invalid Object Type. Please pick from: $($OBJ_TYPES.keys -join ", ")"
        return $null
    }

    return $objType
}

<#
.SYNOPSIS
    Get-ObjName prompts the user for the RDM object name
#>
function Get-ObjName {
    return (Read-Host -Prompt "$($CR)Object Name$CR(eg. LY-NEWSERV99, foldername)$FOOT").Trim()
}

<#
.SYNOPSIS
    Get-ObjGroup prompts the user for the folder the RDM object belongs in, checking that it exists as well
#>
function Get-ObjGroup {

    # Prompt for destination folder with examples
    $objGroup = (Read-Host -Prompt "$($CR)Destination Folder$CR(eg. prd\monitoring, qa\tools)$FOOT").Trim().ToLower()
    $objGroup = $objGroup.Replace('/','\').TrimEnd('\')


    # If the folder doesn't exist, return null
    try {
        if ($null -eq (Get-EODRDMSingleGroupObj -FullGroupPath $objGroup)) { throw }
    }
    catch {
        Write-Warning -Message "Invalid Folder. Please assure the destination folder exists and try again."
        return $null
    }

    return $objGroup

}

<#
.SYNOPSIS
    Get-ObjIP prompts the user for the IP Address, returning null if not properly formatted
#>
function Get-ObjIP {

    # Prompts for IP Address with examples
    $objIP = Read-Host -Prompt "$($CR)IP Address$CR(eg. 10.50.313.47, just hit `"Enter`" if folder)$FOOT"

    # If not skipping IP, check that it matches 255.255.255.255 formatting. If not return null
    if((-not [string]::IsNullOrWhiteSpace($objIP)) -and
    ($objIP -notmatch "(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}")) {
        Write-Warning -Message "Invalid IP Address Formatting. Please enter a valid IP address."
        return $null
    }

    return $objIP
}

<#
.SYNOPSIS
    Get-ObjColor prompts the user for the Icon Color of the object, returning null if not an available color
#>
function Get-ObjColor {
    [CmdletBinding()]
    param (
        # CurrentValue is the current value of the object, to compare to a potential new one
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $CurrentValue
    )

    # Prompts for Color with options
    $prompt = "$($CR)Color$CR($($COLORS.keys -join ", "))$($CR)(If you use Dark Mode, Black == White)$($CR)Current Value: $CurrentValue$FOOT"
    $objColor = (Read-Host -Prompt $prompt).Trim()

    # If the color isn't valid, return null
    if($COLORS.keys -notcontains $objColor) {
        Write-Warning -Message "Invalid Color. Please pick from: $($COLORS.keys -join ", ")"
        return $null
    }

    return $objColor
}

<#
.SYNOPSIS
    Get-ObjCred prompts the user for the Credential Type, returning null if not valid
#>
function Get-ObjCred {
    [CmdletBinding()]
    param (
        # CurrentValue is the current value of the object, to compare to a potential new one
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $CurrentValue
    )

    # Prompts for Credential with options
    $prompt = "$($CR)Server Login Credential$CR($($CRED_TYPES.keys -join ", "))$($CR)Current Value: $CurrentValue$FOOT"
    $objCred = (Read-Host -Prompt $prompt).Trim()

    # IF the credential type isn't valid, return null
    if($CRED_TYPES.keys -notcontains $objCred) {
        Write-Warning -Message "Invalid Credential Type. Please pick from: $($CRED_TYPES.keys -join ", ")"
        return $null
    }

    return $objCred
}

<#
.SYNOPSIS
    Get-ObjUser prompts the user for the Login User
#>
function Get-ObjUser {
    [CmdletBinding()]
    param (
        # CurrentValue is the current value of the object, to compare to a potential new one
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $CurrentValue
    )

    $prompt = "$($CR)Server Login User$CR(.\Administrator, etc.)$($CR)Current Value: $CurrentValue$FOOT"
    return ((Read-Host -Prompt $prompt).Trim())
}

<#
.SYNOPSIS
    Get-ObjGateway prompts the user for the Login Gateway
#>
function Get-ObjGateway {
    [CmdletBinding()]
    param (
        # CurrentValue is the current value of the object, to compare to a potential new one
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $CurrentValue
    )

    $prompt = "$($CR)Gateway Host$CR(ssh, rds, etc.)$($CR)Current Value: $CurrentValue$FOOT"
    return ((Read-Host -Prompt $prompt).Trim())
}

<#
.SYNOPSIS
    Get-ObjGatewayCred prompts the user for the Credential used for the Login Gateway
#>
function Get-ObjGatewayCred {
    [CmdletBinding()]
    param (
        # CurrentValue is the current value of the object, to compare to a potential new one
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $CurrentValue
    )

    $prompt = "$($CR)Gateway Login Credential$CR(DEV, PRODUCTION)$($CR)Current Value: $CurrentValue$FOOT" 
    return ((Read-Host -Prompt $prompt).Trim().ToUpper())
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

    # Header with title of the script
    Write-Output -InputObject "$($CR)ADD NEW RDM OBJECT TO DATABASE"
    Write-Output -InputObject $H1
    Write-Output -InputObject "RDM DATABASE: $((Get-EODRDMCurrentDataSource).Name)$CR"

    # Prompt for object type and name
    $OBJ_TYPE   = Invoke-PromptWhileNull -PromptCommand { Get-ObjType }
    $OBJ_NAME   = Invoke-PromptWhileNull -PromptCommand { Get-ObjName }

    # Based on type of object, change name casing
    if($OBJ_TYPE -eq "FOLDER") {
        $OBJ_NAME = $OBJ_NAME.ToLower()
    }
    else {
        $OBJ_NAME = $OBJ_NAME.ToUpper()
    }

    # Prompt for destination folder and IP address
    $OBJ_GROUP  = Invoke-PromptWhileNull -PromptCommand { Get-ObjGroup }
    $OBJ_IP     = Invoke-PromptWhileNull -PromptCommand { Get-ObjIP }

    # Configure advanced settings
    $OBJ_COLOR          = Get-EODRDMSessionColor -RDMSession (Get-EODRDMSingleGroupObj -FullGroupPath $OBJ_GROUP)
    $OBJ_CRED           = "Inherited"
    $OBJ_USER           = ""
    $OBJ_GATEWAY        = Get-EODRDMDefaultGateway -Type $OBJ_TYPES.$OBJ_TYPE
    $OBJ_GATEWAY_CRED   = ""
    if($OBJ_TYPE -ne "FOLDER") {
        $OBJ_GATEWAY_CRED   = "PRODUCTION"
    }

    # loop when prompted for advanced settings
    do {
        # output settings
        Write-Output -InputObject "$($2CR)OBJECT PARAMETERS"
        Write-Output -InputObject $H1
        Write-Output -InputObject "Name: $OBJ_NAME"
        Write-Output -InputObject "Type: $OBJ_TYPE"
        Write-Output -InputObject "Destination Folder: $OBJ_GROUP"
        Write-Output -InputObject "IP Address: $OBJ_IP"
        Write-Output -InputObject ""
        Write-Output -InputObject "Color: $OBJ_COLOR"
        Write-Output -InputObject "Credential Type: $OBJ_CRED"
        Write-Output -InputObject "Server User (blank if Inherited): $OBJ_USER"
        Write-Output -InputObject "Gateway (blank if Folder): $OBJ_GATEWAY"
        Write-Output -InputObject "Gateway Login Credential: $OBJ_GATEWAY_CRED"
        
        # Sleep to Draw Admin's Eye to Object Params
        Start-Sleep -Seconds 7
    
        # prompt for commit
        Write-Output -InputObject "$($2CR)Commit to RDM Database? (Y)es, (N)o, or (E)dit Additional Settings"
        $commitYNE = Read-Host -Prompt "(y/n/e)"

        # loop for y/n/e
        do {
            switch -Regex ($commitYNE)
            {
                # if yes, commit to the database and exit
                '^(?i:y|yes)$' {
                    $addEODRDMSessionParams = @{
                        Name            = $OBJ_NAME
                        Type            = $OBJ_TYPES.$OBJ_TYPE
                        Group           = $OBJ_GROUP
                        IP              = $OBJ_IP
                        Icon            = $COLORS.$OBJ_COLOR
                        CredType        = $CRED_TYPES.$OBJ_CRED
                        ServerUser      = $OBJ_USER
                        Gateway         = $OBJ_GATEWAY
                        GatewayCred     = $OBJ_GATEWAY_CRED
                        WarningAction   = "Stop"
                    }
                    Add-EODRDMSession @addEODRDMSessionParams
                    Write-Output -InputObject "Commit accepted."
                    Write-Output -InputObject "Don't forget to delete the old server, if you are replacing. :) Servers can always be added back."
                    Write-Output -InputObject "Updating RDM Application to reflect new object."
                    Update-EODRDMUI
                }

                # if no, exit
                '^(?i:n|no)$' {
                    Write-Output -InputObject "Commit rejected. Exiting."
                }

                # if edit, prompt for advanced settings
                '^(?i:e|edit)$' {
                    $OBJ_COLOR          = Invoke-PromptWhileNull -PromptCommand { Get-ObjColor -CurrentValue $OBJ_COLOR }
                    $OBJ_CRED           = Invoke-PromptWhileNull -PromptCommand { Get-ObjCred -CurrentValue $OBJ_CRED }
                    $OBJ_USER           = Invoke-PromptWhileNull -PromptCommand { Get-ObjUser -CurrentValue $OBJ_USER }
                    $OBJ_GATEWAY        = Invoke-PromptWhileNull -PromptCommand { Get-ObjGateway -CurrentValue $OBJ_GATEWAY }
                    $OBJ_GATEWAY_CRED   = Invoke-PromptWhileNull -PromptCommand { Get-ObjGatewayCred -CurrentValue $OBJ_GATEWAY_CRED }
                }
                default {
                    Write-Output -InputObject "Please enter yes, no, or edit."
                }
            }
        } while ($commitYNE -notmatch "^(?i:y|n|e|yes|no|edit)$")
    } while ($commitYNE -notmatch "^(?i:y|n|yes|no)$")
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