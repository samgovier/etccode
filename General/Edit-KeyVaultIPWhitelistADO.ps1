<#
.SYNOPSIS
    Edit-KeyVaultIPWhitelistADO is a script that either adds or removes IPs of an ADO agent for key vault editing.

    NOTES:
    - The Public IP pull defaults to a special DNS request done to OpenDNS.
        There is an alternative option to make a web request instead.
    - The remove function removes all IPs, instead of only the agent's IP.
        This is for higher security, as the key vault is not expected to have any long-term allowed IPs.

    PREREQ:
    - This should generally be run as an Azure PowerShell task in ADO. If it's run outside of this,
        you will need to set the subscription and import the Az.KeyVault module before running.

.PARAMETER RGName
    RGName is the name of the resource group the key vault is in.

.PARAMETER VaultName
    VaultName is the name of the Key Vault.

.PARAMETER Remove
    Remove is a switch that tells the script to remove IPs, instead of add. Default is off.

.PARAMETER IPAddOverride
    IPAddOverride allows for providing the IP address instead of pulling the Public IP of the machine. It's unused by default.

.PARAMETER PubIPWebMethod
    PubIPWebMethod is a switch that tells the script to use the web request method of pulling the public IP. Default is off.

.EXAMPLE
    ADO release task configuration:
    Script Path: .\Edit-KeyVaultIPWhitelistADO.ps1
    Script Arguments: -VaultName dev-kv-wus -RGName dev-rg-wus -Remove
    Run this task even if a task is failed, even if the deployment is cancelled

.NOTES
    File Name       : Edit-KeyVaultIPWhitelistADO.ps1
    Author          : Sam Govier
    Creation Date   : 10/30/2024
#>

#region Config

[CmdletBinding()]
param
(
    # RGName is the name of the resource group
    [Parameter(Mandatory=$true)]
    [string]
    $RGName,

    # VaultName is the name of the key vault
    [Parameter(Mandatory=$true)]
    [string]
    $VaultName,

    # Remove marks whether to remove IPs, instead of add
    [Parameter(Mandatory=$false)]
    [switch]
    $Remove,

    # IPAddOverride is an optional parameter to provide the IP address to add, instead of automatically pulling
    [Parameter(Mandatory=$false)]
    [string]
    $IPAddOverride,

    # PubIPWebMethod marks whether to use a web request to pull public IP, instead of a DNS lookup
    [Parameter(Mandatory=$false)]
    [switch]
    $PubIPWebMethod
)

#endregion Config

#region Execution

# if we're removing, pull all remaining IPs from the key vault and exit
if($Remove) {

    Write-Host -Object "Removing all IPs from $VaultName..."
    Write-Verbose -Message "Pulling all allowed IP ranges from $VaultName in $RGName"
    $allowedIPs = (Get-AzKeyVault -VaultName $VaultName -ResourceGroupName $RGName).NetworkAcls.IpAddressRanges

    foreach($IP in $allowedIPs) {
        Write-Verbose -Message "Deleting IP range $IP"
        Remove-AzKeyVaultNetworkRule -VaultName $VaultName -ResourceGroupName $RGName -IpAddressRange $IP
    }

    Write-Host -Object "Removal done!"
    return
}

## otherwise, we're adding
Write-Host -Object "Adding public IP to $VaultName..."

# pubIPAddr wlil be used to add to the key vault. Starting with the override
$pubIPaddr = $IPAddOverride

# if the override is empty, pull the public IP
if([string]::IsNullOrWhiteSpace($IPAddOverride)) {

    # if we specified web request to pull the IP, do that, otherwise DNS request
    if($PubIPWebMethod) {
        # icanhazip.com (a Cloudflare server) returns your public IP as a string
        Write-Verbose -Message "Public IP: web request from icanhazip.com..."
        $pubIPaddr = ((Invoke-RestMethod "icanhazip.com").Trim())
    }
    else {
        # myip.opendns.com. is a special OpenDNS domain that is programmed to return the IP address the request is coming from
        Write-Verbose -Message "Public IP: DNS request from myip.opendns.com..."
        $pubIPaddr = ((Resolve-DnsName -Name "myip.opendns.com." -Server "resolver1.opendns.com").IPAddress)
    }
}
else {
    Write-Verbose -Message "Public IP: override: $IPAddOverride"
}

Write-Verbose -Message "Adding the IP $pubIPaddr to key vault $VaultName in $RGName"
Add-AzKeyVaultNetworkRule -VaultName $VaultName -ResourceGroupName $RGName -IpAddressRange $pubIPaddr

Write-Host -Object "Addition done!"

#endregion Execution
