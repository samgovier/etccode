<#
    In order to unblock the Dell Powershell SDK,
    Run this script to unblock all files and configure Powershell to allow remote sources:
    https://stackoverflow.com/questions/19957161/add-type-load-assembly-from-network-unc-share-error-0x80131515/19957173#19957173
#>

Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File