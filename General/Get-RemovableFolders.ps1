<#
.SYNOPSIS
    This script compares the C:\Users directory to Active Directory and writes out the folders of users that are no longer enabled.

.EXAMPLE
    Configure the $servers variable
    Run from a folder with the AD module, eg. MA-OPSTOOLS02

.NOTES
    File Name       : Get-RemovableFolders.ps1
    Author          : Sam Govier
    Creation Date   : 05/26/2021
#>

$servers = @(
)

$usersDir = "\c$\users"


foreach($server in $servers) {
    Write-Host ($server + "`n==========")

    Get-ChildItem -Path "\\$server$usersDir" -Directory | ForEach-Object -Process {
        try {
            $adUserData = Get-ADUser $PSItem.Name
        
            if (-not ($adUserData).Enabled) {
                Write-Host $PSItem.Name
            }
        }
        catch {}

    }

    Write-Host "----------`n"
}