<#
.SYNOPSIS
    This powershell profile is for loading required Chef Workstation components into a new Powershell Session.
    NOTE: this profile does not modify the PATH variable. Assure you have the following path in $env:PATH:
    C:\opscode\chef-workstation\bin\


.NOTES
    File Name       : CHEF_Microsoft.PowerShell_profile.ps1
    Author          : Sam Govier
    Creation Date   : 03/01/21
#>

#region Config

# STARTING_PATH is the working directory on start-up
$STARTING_PATH = "$HOME/Source/esker/chef"

#endregion Config

#region Functions

<#
.SYNOPSIS
    Initialize-CwWorkspace contains all the necessary calls to set-up the Chef environment.
#>
function Initialize-CwWorkspace
{
    # set an environment variable from the official script, then run shell-init
    $env:CHEFWS_ENV_FIX = 1
    chef shell-init powershell | Out-Null

    # import the chef Powershell module
    Import-Module chef -DisableNameChecking

    # cd to the chef source code folder
    cd $STARTING_PATH
}

<#
.SYNOPSIS
    This function checks that the prompt is in admin mode, and returns false if it is not.
#>
function Test-AdminPrompt
{
    # check for admin mode in this prompt
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Error -Message "Chef Workstation requires an Administrative prompt. Please run Powershell as an administrator."
        return $false
    }
    
    return $true
}

<#
.SYNOPSIS
    this function is for use by the system to display the custom CW command prompt.
#>
function Prompt
{
"CW " + (Get-Location) + "> "
}

#endregion Functions

#region Execution

# if we're in an admin prompt, load CW modules. Otherwise hold on loop to emphasize error
if (Test-AdminPrompt)
{
    Initialize-CwWorkspace
    Write-Host "Chef Workstation profile loaded.`n"
}
else
{
    while ($true) {}
}

# Prompt is implied called here, used as the custom command prompt

#endregion Execution


