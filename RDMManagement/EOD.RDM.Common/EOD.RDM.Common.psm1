#region General

<#
.SYNOPSIS
    This function returns the current connected Data Source.
#>
function Get-EODRDMCurrentDataSource {
    [CmdletBinding()]
    param()

    return Get-RDMCurrentDataSource
}

<#
.SYNOPSIS
    This function set the connected Data Source for RDM management.
#>
function Set-EODRDMCurrentDataSource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [RemoteDesktopManager.PowerShellModule.PSOutputObject.PSDataSource]
        $DataSource
    )

    Set-RDMCurrentDataSource -DataSource $DataSource
}

<#
.SYNOPSIS
    This function gets all configured Data Source connections, or the one based on the provided name.
#>
function Get-EODRDMDataSource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [string]
        $Name
    )

    if (([string]::IsNullOrWhiteSpace($Name))) {
        return (Get-RDMDataSource)
    }

    return (Get-RDMDataSource -Name $Name)
}

<#
.SYNOPSIS
    This function gets all RDM session objects (machines and folders), or the ones based on the provided name.
#>
function Get-EODRDMSession {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [string]
        $Name
    )
    
    if (([string]::IsNullOrWhiteSpace($Name))) {
        return (Get-RDMSession)
    }

    return (Get-RDMSession -Name $Name)
}

<#
.SYNOPSIS
    This function gets all child RDM session objects under a group (folder) object.
#>
function Get-EODRDMChildSessions {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $FullGroupPath
    )

    # pull session objects in the immediate directory
    $surfaceSesh = [Object[]](Get-EODRDMSession | Where-Object -FilterScript { (-not $PSItem.ConnectionType.ToString().Equals("Group")) -and ($PSItem.Group.Equals($FullGroupPath.Trim('\'))) })
    # recurse to pull all further items
    $recurse = [Object[]](Get-EODRDMSession | Where-Object -FilterScript { $PSItem.Group.Contains($FullGroupPath) })

    # return a combo of both items
    return ($surfaceSesh + $recurse)
}

<#
.SYNOPSIS
    This function gets the specific group (folder) object using the name and containing group.
#>
function Get-EODRDMSingleGroupObj {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $FullGroupPath
    )
    return (Get-EODRDMSession -Name $FullGroupPath.TrimEnd('\').Split('\')[-1] | Where-Object -Property Group -eq $FullGroupPath.TrimEnd('\'))
}

<#
.SYNOPSIS
    This function takes a session object that exists in memory and sets it in the RDM database, writing changes.
#>
function Set-EODRDMSession {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Session
    )

    Set-RDMSession -Session $Session
}

<#
.SYNOPSIS
    This function creates, modifies and commits a new RDM session object to the database.
    Besides the provided configuration information in the parameters, it uses default settings from Set-EODRDMDefaultSettings.
#>
function Add-EODRDMSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $Group,
        [Parameter(Mandatory=$true)]
        [string]
        $CredType,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $Icon,
        [Parameter(Mandatory=$false)]
        [string]
        $IP,
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]
        $Gateway,
        [Parameter(Mandatory=$false)]
        [string]
        [AllowEmptyString()]
        $GatewayCred,
        [Parameter(Mandatory=$false)]
        [string]
        $ServerUser
    )

    Write-Verbose -Message "Creating: $Name, Under: $Group"
    $newSession = New-RDMSession -Name $Name -Type $Type -Group $Group -Host $IP

    Write-Verbose -Message "Setting Icon"
    $newSession.ImageName = $Icon

    Write-Verbose -Message "Configuring default settings for session object"
    Set-EODRDMDefaultSettings -RDMSession $newSession -Gateway $Gateway

    Write-Verbose -Message "Setting Credential Type"
    Set-RDMSessionCredentials -PSConnection $newSession -CredentialsType $CredType

    Write-Verbose -Message "Setting User if present"
    Set-EODRDMSessionServerUser -RDMSession $newSession -ServerUser $ServerUser

    if(-not [string]::IsNullOrWhiteSpace($Gateway)) {
        Write-Verbose -Message "Setting Gateway Host if present"
        Set-EODRDMSessionGatewayHost -RDMSession $newSession -Gateway $Gateway

        Write-Verbose -Message "Setting Gateway Credential if present"
        Set-EODRDMSessionGatewayCred -RDMSession $newSession -GatewayCred $GatewayCred
    }

    Write-Verbose -Message "Committing new object to database"
    Set-EODRDMSession -Session $newSession
}

<#
.SYNOPSIS
    This function pulls the server user information based on the host type and cred type.
#>
function Get-EODRDMSessionServerUser {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession
    )

    switch (Get-EODRDMSessionCredentialType -RDMSession $RDMSession) {
        "PrivateVaultSearch" {
            return ($RDMSession.CredentialPrivateVaultSearchString)
        }
        "SessionSpecific" {
            if ($RDMSession.ConnectionType -eq "SSHShell") {
                return ($RDMSession.Terminal.Username)
            }
            if ($RDMSession.ConnectionType -eq "RDPConfigured") {
                return ($RDMSession.RDP.UserName)
            }
        }
    }

    return ""
}

<#
.SYNOPSIS
    Given a session object and server user, sets the appropriate property based on the host type and cred type.
#>
function Set-EODRDMSessionServerUser {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $ServerUser
    )

    switch (Get-EODRDMSessionCredentialType -RDMSession $RDMSession) {
        "PrivateVaultSearch" {
            $RDMSession.CredentialPrivateVaultSearchString = $ServerUser
        }
        "SessionSpecific" {
            if ($RDMSession.ConnectionType -eq "SSHShell") {
                $RDMSession.Terminal.Username = $ServerUser
            }
            elseif ($RDMSession.ConnectionType -eq "RDPConfigured") {
                $RDMSession.RDP.UserName = $ServerUser
            }    
        }
    }
}

<#
.SYNOPSIS
    This function pulls the gateway credential information based on the host type: SSH or RDP.
#>
function Get-EODRDMSessionGatewayCred {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession
    )

    if ($RDMSession.ConnectionType -eq "SSHShell") {
        return ($RDMSession.Terminal.SSHGateways[0].PrivateVaultString)
    }
    if ($RDMSession.ConnectionType -eq "RDPConfigured") {
        return ($RDMSession.RDP.GatewayPrivateVaultSearchString)
    }
    
    return ""

}

<#
.SYNOPSIS
    Given a session object and gateway credential, sets the appropriate property based on the host type: SSH or RDP.
#>
function Set-EODRDMSessionGatewayCred {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $GatewayCred
    )

    if ($RDMSession.ConnectionType -eq "SSHShell") {
        $RDMSession.Terminal.SSHGateways[0].PrivateVaultString = $GatewayCred
    }
    elseif ($RDMSession.ConnectionType -eq "RDPConfigured") {
        $RDMSession.RDP.GatewayPrivateVaultSearchString = $GatewayCred
    }    
}

<#
.SYNOPSIS
    This function pulls the gateway host information based on the host type: SSH or RDP.
#>
function Get-EODRDMSessionGatewayHost {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession
    )

    if ($RDMSession.ConnectionType -eq "SSHShell") {
        return ($RDMSession.Terminal.SSHGateways[0].Host)
    }
    if ($RDMSession.ConnectionType -eq "RDPConfigured") {
        return ($RDMSession.RDP.GatewayHostname)
    }
    
    return ""
}

<#
.SYNOPSIS
    Given a session object and gateway host, sets the appropriate property based on the host type: SSH or RDP.
#>
function Set-EODRDMSessionGatewayHost {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        $Gateway
    )

    if ($RDMSession.ConnectionType -eq "SSHShell") {
        $RDMSession.Terminal.SSHGateways[0].Host = $Gateway
    }
    elseif ($RDMSession.ConnectionType -eq "RDPConfigured") {
        $RDMSession.RDP.GatewayHostname = $Gateway
    }    
}

<#
.SYNOPSIS
    This function returns the credential settings of the passed RDM session object.
#>
function Get-EODRDMSessionCredentialType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $RDMSession
    )

    return (Get-RDMSessionCredentials -PSConnection $RDMSession)
}

<#
.SYNOPSIS
    This function refreshes the RDM application UI.
#>
function Update-EODRDMUI {
    [CmdletBinding()]
    param()

    Update-RDMUI
}

#endregion General

#region Defaults

<#
.SYNOPSIS
    This function returns the current defaults for gateway host, based on session type.
#>
function Get-EODRDMDefaultGateway {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Type
    )

    if($Type -eq "RDPConfigured") {
        return ""
    }
    if($Type -eq "SSHShell") {
        return ""
    }
    return ""
}

<#
.SYNOPSIS
    This function sets all the etcetera defaults based on host type for the passed RDM sesion object.
#>
function Set-EODRDMDefaultSettings {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $RDMSession,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $Gateway
    )

    switch ($RDMSession.ConnectionType)
    {
        "SSHShell" {
            if(-not [string]::IsNullOrWhiteSpace($Gateway)) {
                Write-Verbose -Message "Setting Base SSH Gateway config"
                $RDMSession.Terminal.SSHGateways = New-Object -TypeName Devolutions.RemoteDesktopManager.Business.SSHGateway
                $RDMSession.Terminal.SSHGateways[0].CredentialSource = "PrivateVaultSearch"
                $RDMSession.Terminal.AlwaysAcceptFingerprint = $true
                $RDMSession.Terminal.UseSSHGateway = $true
            }

            Write-Verbose -Message "Setting SSH UI config"
            $RDMSession.Terminal.FontMode = "Override"
        }
        "RDPConfigured" {
            if(-not [string]::IsNullOrWhiteSpace($Gateway)) {
                Write-Verbose -Message "Setting Base RDP Gateway config"
                $RDMSession.RDP.ConnectionType = "LowSpeedBroadband"
                $RDMSession.RDP.GatewayProfileUsageMethod = "Explicit"
                $RDMSession.RDP.GatewaySelection = "SpecificGateway"
                # This sets RDP Gateway Credentials to use the User Vault
                $RDMSession.RDP.GatewayCredentialConnectionID = "88E4BE76-4C5B-4694-AA9C-D53B7E0FE0DC"
                $RDMSession.RDP.GatewayUsageMethod = "ModeDirect"
                $RDMSession.RDP.GatewayCredentialsSource = "UserPassword"
                $RDMSession.RDP.PingForGateway = $true
            }


            Write-Verbose -Message "Setting RDP UI config"
            $RDMSession.DisableFullWindowDrag = $true
            $RDMSession.DisableMenuAnims = $true
            $RDMSession.DisableThemes = $true
            $RDMSession.DisableWallpaper = $true
            $RDMSession.ScreenColor = "C16Bits"
        }
    }
}

#endregion Defaults