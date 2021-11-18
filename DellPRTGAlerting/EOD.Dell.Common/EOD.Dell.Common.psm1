#region General

<#
.SYNOPSIS
This function will attempt to connect to a Dell Storage Manager, given a username, password and hostname
#>
function Connect-EODDellScConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        [Parameter(Mandatory=$true)]
        [string]
        $Hostname,

        [Parameter(Mandatory=$false)]
        [SecureString]
        $Password = $null
    )

    # if there is no password, pull the secure string from the local password store
    if($null -eq $Password)
    {
        $Password = Get-EODDellScPwSecureString -Hostname $Hostname
    }

    return Connect-DellApiConnection -HostName $Hostname -User $Username -Password $Password
}

<#
.SYNOPSIS
    This function will close an existing Dell connection
#>
function Disconnect-EODDellScConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn
    )

    Disconnect-DellApiConnection -Connection $DellApiConn
}

<#
.SYNOPSIS
    This function will pull the pre-generated Dell password for the corresponding hostname and Windows user
    Password generated via Set-PasswordForStorageDevice.ps1
#>
function Get-EODDellScPwSecureString {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Hostname
    )

    $passHash = Get-Content -Path "$PSScriptRoot/pw/$($Hostname)_$($env:USERNAME)"
    $securePw = $passHash | ConvertTo-SecureString
    return $securePw
}

<#
.SYNOPSIS
    This function is a wrapper to return all Dell Volume objects
#>
function Get-EODDellScVolume {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellScVolume -Connection $DellApiConn)
    }

    return (Get-DellScVolume -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)
}

<#
.SYNOPSIS
    This function is a wrapper to return all Dell Storage Tier objects
#>
function Get-EODDellScStorageTypeTier {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellScStorageTypeTier -Connection $DellApiConn)
    }

    return (Get-DellScStorageTypeTier -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)
}

<#
.SYNOPSIS
    This function is a wrapper to return Dell Storage Center objects
#>
function Get-EODDellStorageCenter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellStorageCenter -Connection $DellApiConn)
    }

    return (Get-DellStorageCenter -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)
}

<#
.SYNOPSIS
    This function is a wrapper to return Dell disk objects
#>
function Get-EODDellScDiskConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellScDiskConfiguration -Connection $DellApiConn)
    }

    return (Get-DellScDiskConfiguration -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)

}

<#
.SYNOPSIS
    This function is a wrapper to return Dell controller objects
#>
function Get-EODDellScController {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellScController -Connection $DellApiConn)
    }

    return (Get-DellScController -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)
}

<#
.SYNOPSIS
    This function is a wrapper to return Dell Enclosure Power Supplies
#>
function Get-EODDellScEnclosurePowerSupply {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    if ($ScSerialNumber -eq -1) {
        return (Get-DellScEnclosurePowerSupply -Connection $DellApiConn)
    }

    return (Get-DellScEnclosurePowerSupply -Connection $DellApiConn -ScSerialNumber $ScSerialNumber)
}

<#
.SYNOPSIS
    This function takes the error info given, and returns the PRTG formatted proper XML.
#>
function Add-EODDellPRTGError {
    [CmdletBinding()]
    param (
        # ErrorMessage is the error message to return in PRTG
        [Parameter(Mandatory=$true)]
        [string]
        $ErrorMessage
    )

    # Translate error value and message into PRTG XML and return
    $ErrAdd = "<error>1</error>`r`n"
    $ErrAdd += "<text>$ErrorMessage</text>`r`n"
    return $ErrAdd
}

<#
.SYNOPSIS
    This function takes a bunch of information about a PRTG channel and outputs the well-formatted XML to match.
#>
function Add-EODDellPRTGChannel {
    [CmdletBinding()]
    param (

        # ChannelName is the name of the channel
        [Parameter(Mandatory=$true)]
        [string]
        $ChannelName,
        
        # ChannelValue is the value returned for that timestamp (eg. percentage, bytes, seconds)
        [Parameter(Mandatory=$true)]
        [string]
        $ChannelValue,

        # PRTG Unit type, default is Custom.
        [Parameter(Mandatory=$false)]
        [string]
        $Unit="Custom",

        # CustomUnit is the text displayed if the Unit is custom
        [Parameter(Mandatory=$false)]
        [string]
        $CustomUnit=$null,

        # Float is a switch that needs to be set if ChannelValue is not an Integer
        [Parameter(Mandatory=$false)]
        [switch]
        $Float
    )

    # Translate input values into XML and return
    $XmlAdd = "<result>`r`n" 
    $XmlAdd += "<channel>$ChannelName</channel>`r`n"
    $XmlAdd += "<value>$ChannelValue</value>`r`n"
    $XmlAdd += "<Unit>$Unit</Unit>`r`n"
    if ($null -ne $CustomUnit) { $XmlAdd += "<CustomUnit>$CustomUnit</CustomUnit>`r`n" }
    if ($Float) { $XmlAdd += "<Float>1</Float>`r`n" }
    $XmlAdd += "</result>`r`n"  
    return $XmlAdd 
}

<#
    This function converts a microsecond value to a millisecond value, and rounds
#>
function ConvertTo-MsFromMicro {
    # MicroVal is the Microsecond Value
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double]
        $MicroVal
    )

    return [math]::Round(($MicroVal * 0.001),2)
}

#endregion General

#region Capacity

<#
.SYNOPSIS
    This function pulls volume byte information and outputs the percent free space remaining
#>
function Get-EODDellScVolumePercentFreeSpace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$true)]
        $VolumeInstanceId,

        [Parameter(Mandatory=$false)]
        [int]
        $retries = 5
    )

    # try multiple connects: on 0 retries, throw connection exception
    for($r = $retries; $r -ge 0; $r--) {
        try {
            # storageUsage gets a bunch of information about volume storage usage
            $storageUsage = Get-DellScVolumeStorageUsage -Connection $DellApiConn -Instance $VolumeInstanceId

            # do the math
            return [math]::Round((100 * ($storageUsage.FreeSpace.ByteSize / $storageUsage.ConfiguredSpace.ByteSize)),2)
        }
        catch [DellStorage.Api.Communication.DellStorageApiMethodException]  {
            if ($r -le 0) {
                throw $PSItem
            }
        }
    }
}

<#
.SYNOPSIS
    This function pulls volume byte information and outputs the free bytes remaining
#>
function Get-EODDellScVolumeFreeBytes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$true)]
        $VolumeInstanceId,

        [Parameter(Mandatory=$false)]
        [int]
        $retries = 5
    )
        

    # try multiple connects: on 0 retries, throw connection exception
    for($r = $retries; $r -ge 0; $r--) {
        try {
            # storageUsage gets a bunch of information about volume storage usage
            $storageUsage = Get-DellScVolumeStorageUsage -Connection $DellApiConn -Instance $VolumeInstanceId
            return $storageUsage.FreeSpace.ByteSize
        }
        catch [DellStorage.Api.Communication.DellStorageApiMethodException]  {
            if ($r -le 0) {
                throw $PSItem
            }
        }
    }
}

<#
.SYNOPSIS
    This function pulls tier byte information and outputs the percent free space remaining
#>
function Get-EODDellScTierPercentFreeSpace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$true)]
        $TierInstanceId,

        [Parameter(Mandatory=$false)]
        [int]
        $retries = 5
    )

    # try multiple connects: on 0 retries, throw connection exception
    for($r = $retries; $r -ge 0; $r--) {
        try {
            # storageUsage gets a bunch of information about tier storage usage
            $storageUsage = Get-DellScStorageTypeTierStorageUsage -Connection $DellApiConn -Instance $TierInstanceId

            # do the math
            return [math]::Round((100 * (1 - ($storageUsage.UsedSpace.ByteSize / ($storageUsage.NonAllocatedSpace.ByteSize + $storageUsage.AllocatedSpace.ByteSize)))),2)
        }
        catch [DellStorage.Api.Communication.DellStorageApiMethodException]  {
            if ($r -le 0) {
                throw $PSItem
            }
        }
    }
}

<#
.SYNOPSIS
    This function pulls tier byte information and outputs the free bytes remaining
#>
function Get-EODDellScTierFreeBytes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$true)]
        $TierInstanceId,

        [Parameter(Mandatory=$false)]
        [int]
        $retries = 5
    )

    # try multiple connects: on 0 retries, throw connection exception
    for($r = $retries; $r -ge 0; $r--) {
        try {
            # storageUsage gets a bunch of information about tier storage usage
            $storageUsage = Get-DellScStorageTypeTierStorageUsage -Connection $DellApiConn -Instance $TierInstanceId
            return ($storageUsage.FreeSpace.ByteSize + $storageUsage.NonAllocatedSpace.ByteSize)
        }
        catch [DellStorage.Api.Communication.DellStorageApiMethodException]  {
            if ($r -le 0) {
                throw $PSItem
            }
        }
    }
}

#endregion Capacity

#region Latency

<#
.SYNOPSIS
    This function pulls IO information for all volumes in all available storage centers
#>
function Get-EODDellVolumeIoData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    # volumeIoCollection is a list of volumes with IO information
    $volumeIoCollection = @()

    # in case we have multiple storage centers, pull all of them and get volume IO data for each
    Get-EODDellStorageCenter -DellApiConn $DellApiConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        $volumeIoCollection += Get-DellStorageCenterLatestScVolumeIoUsage -Connection $DellApiConn -Instance $PSItem.InstanceId
    }

    return $volumeIoCollection
}

#endregion Latency

#region Health

<#
.SYNOPSIS
    This function pulls and outputs the names of all disks that have a status other than "Healthy".
#>
function Get-EODDellUnhealthyDisks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    # unhealthDisks is a list of disks that aren't healthy
    $unhealthyDisks = @()

    # if the status isn't "Healthy" for a disk, add to the list
    Get-EODDellScDiskConfig -DellApiConn $DellApiConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        if ($PSItem.HealthDescription -ne "Healthy") {
            $unhealthyDisks += $PSItem.InstanceName
        }
    }

    return $unhealthyDisks
}

<#
.SYNOPSIS
    This function pulls and outputs the names of all volumes that have a status other than "Healthy".
#>
function Get-EODDellUnhealthyVolumes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    # unhealthyVolumes is a list of volumes that aren't healthy
    $unhealthyVolumes = @()

    # if the status isn't "Up" for a volume, add to the list
    Get-EODDellScVolume -DellApiConn $DellApiConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        if ($PSItem.Status -ne "Up") {
            $unhealthyVolumes += $PSItem.InstanceName
        }
    }

    return $unhealthyVolumes
}

<#
.SYNOPSIS
    This function pulls and outputs the names of all controllers that have a status other than Up.
#>
function Get-EODDellUnhealthyCont {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    # unhealthyCont is a list of controllers that aren't healthy
    $unhealthyCont = @()

    # if the status isn't "Up" for a controller, add to the list
    Get-EODDellScController -DellApiConn $DellApiConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        if ($PSItem.Status -ne "Up") {
            $unhealthyCont += $PSItem.Name
        }
    }

    return $unhealthyCont
}

<#
.SYNOPSIS
    This function pulls and outputs the names of all power supplies that have a status other than Up.
#>
function Get-EODDellUnhealthyPower {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $DellApiConn,

        [Parameter(Mandatory=$false)]
        [long]
        $ScSerialNumber = -1
    )

    # unhealthyPower is a list of power supplies that aren't healthy
    $unhealthyPower = @()

    # if the status isn't "Up" for a power supply, add to the list
    Get-EODDellScEnclosurePowerSupply -DellApiConn $DellApiConn -ScSerialNumber $ScSerialNumber | ForEach-Object -Process {
        if ($PSItem.Status -ne "Up") {
            $unhealthyPower += "$($PSItem.Location) Power Supply"
        }
    }

    return $unhealthyPower
}

#endregion Health