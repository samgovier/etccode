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
        [string]
        $Icon,
        [Parameter(Mandatory=$false)]
        [string]
        $IP,
        [Parameter(Mandatory=$false)]
        [string]
        $Gateway
    )

    Write-Verbose -Message "Creating: $Name, Under: $Group"
    $newSession = New-RDMSession -Name $Name -Type $Type -Group $Group -Host $IP

    Write-Verbose -Message "Setting Credential Type"
    Set-RDMSessionCredentials -PSConnection $newSession -CredentialsType $CredType

    Write-Verbose -Message "Setting Icon"
    $newSession.ImageName = $Icon

    Write-Verbose -Message "Configuring default settings for session object"
    Set-EODRDMDefaultSettings -RDMSession $newSession -Gateway $Gateway
    
    Write-Verbose -Message "Committing new object to database"
    Set-RDMSession -Session $newSession
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
        return ($rdmSession.Terminal.SSHGateways[0].Host)
    }
    if ($RDMSession.ConnectionType -eq "RDPConfigured") {
        return ($rdmSession.RDP.GatewayHostname)
    }
    
    return ""
}

<#
.SYNOPSIS
    This function returns the credential settings of the passed RDM session object.
#>
function Get-EODRDMSessionCredentials {
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
        $Gateway
    )

    switch ($RDMSession.ConnectionType)
    {
        "SSHShell" {
            Write-Verbose -Message "Setting SSH Gateway config"
            $RDMSession.Terminal.SSHGateways = New-Object -TypeName Devolutions.RemoteDesktopManager.Business.SSHGateway
            $RDMSession.Terminal.SSHGateways[0].Host = $Gateway
            $RDMSession.Terminal.SSHGateways[0].CredentialSource = "PrivateVaultSearch"
            $RDMSession.Terminal.SSHGateways[0].PrivateVaultString = ""
            $RDMSession.Terminal.AlwaysAcceptFingerprint = $true
            $RDMSession.Terminal.UseSSHGateway = $true

            Write-Verbose -Message "Setting SSH UI config"
            $RDMSession.Terminal.FontMode = "Override"

            if (($RDMSession.Name.ToUpper().Contains("-RHEL-") -and (-not $RDMSession.Name.ToUpper().Contains(""))) -or $RDMSession.Name.ToUpper().Contains("-OPSDB")) {
                Write-Verbose -Message "Setting IPA config"
                Set-RDMSessionCredentials -PSConnection $RDMSession -CredentialsType "PrivateVaultSearch"
                $RDMSession.CredentialPrivateVaultSearchString = "IPA"
            }
        }
        "RDPConfigured" {
            Write-Verbose -Message "Setting RDP Gateway config"
            $RDMSession.RDP.ConnectionType = "LowSpeedBroadband"
            $RDMSession.RDP.GatewayProfileUsageMethod = "Explicit"
            $RDMSession.RDP.GatewaySelection = "SpecificGateway"
            $RDMSession.RDP.GatewayHostname = $Gateway
            # This sets RDP Gateway Credentials to use the User Vault
            $RDMSession.RDP.GatewayCredentialConnectionID = "88E4BE76-4C5B-4694-AA9C-D53B7E0FE0DC"
            $RDMSession.RDP.GatewayPrivateVaultSearchString = ""
            $RDMSession.RDP.GatewayUsageMethod = "ModeDirect"
            $RDMSession.RDP.GatewayCredentialsSource = "UserPassword"
            $RDMSession.RDP.PingForGateway = $true

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