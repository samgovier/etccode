<#
.SYNOPSIS
    Tiny script to create a Dell password file for the corresponding Windows user
    This should be run by the user that needs to connect to a Dell SC, eg. the PRTG service user
    It pulls data interactively while running, so it must be run by a user who can provide host and password info    
#>

# ask for the password as a secureString
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString

# ask for the hostname
$Hostname = Read-Host -Prompt "Enter corresponding hostname"

# turn the secure string into a plain text hash
$SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString

# write the hash content into the \pw\ folder
Set-Content -Path "$PSScriptRoot\\pw\\$($Hostname)_$($env:USERNAME)" -Value $SecureStringAsPlainText