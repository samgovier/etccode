<#
.SYNOPSIS
    Invoke-GitMerge merges one source branch into a destination branch. It uses git commands directly, with verbose and exception abilities.

.PARAMETER DestinationBranchName
    DestinationBranchName is the name of the branch to merge into.

.PARAMETER SourceBranchName
    SourceBranchName is the name of the branch to merge from.

.EXAMPLE
    YAML example:
      - powershell: BuildScripts/Invoke-GitMerge.ps1 -DestinationBranchName $(general-access-branch) -SourceBranchName $(early-access-branch) -TriggerBranchName $(Build.SourceBranchName) -Verbose:$$(System.Debug)
        displayName: "Merge EA to GA"

.NOTES
    File Name       : Invoke-GitMerge.ps1
    Author          : Sam Govier
    Creation Date   : 1/18/2023
#>

#region Config

[CmdletBinding()]
param (
    # DestinationBranchName is the name of the branch to merge into
    [Parameter(Mandatory = $true)]
    [string]
    $DestinationBranchName,

    # SourceBranchName is the name of the branch to merge from
    [Parameter(Mandatory = $true)]
    [string]
    $SourceBranchName,

    # TriggerBranchName is the name of the branch this script is triggered from
    [Parameter(Mandatory = $true)]
    [string]
    $TriggerBranchName
)

# IsVerbose is a boolean that determines if the script is running in Verbose mode
$IsVerbose = ($PSBoundParameters['Verbose']) -or ($VerbosePreference -eq 'Continue')

#endregion Config

#region Functions

<#
.SYNOPSIS
    Invokes an external utility (aka. executable), catching errors if they are thrown.

    Adapted from mklement0 on Stack Overflow: https://stackoverflow.com/a/48877892

.EXAMPLE
    Invoke-Utility git push
#>
function Invoke-Utility {
    # split out the passed args to variables
    $exe, $argsForExe = $Args
    $ErrorActionPreference = 'Continue'
    # try to run the command
    try {
        & $exe $argsForExe
    }
    # catch if the executable doesn't exist
    catch {
        throw
    }
    # if the exe exits with a code that isn't 0, throw a hard error
    if ($LASTEXITCODE) {
        throw "$exe indicated failure (exit code $($LASTEXITCODE); full command: $($Args))."
    }
}

#endregion Functions

#region Execution

Write-Output -InputObject "Merging branch '$SourceBranchName' into branch '$DestinationBranchName'"

Write-Output -InputObject ""

Write-Verbose -Message "Checking out branch '$DestinationBranchName'"

Invoke-Utility git checkout $DestinationBranchName

Write-Output -InputObject ""

Write-Verbose -Message "Requesting merge of '$SourceBranchName' into '$DestinationBranchName'"

if ($IsVerbose) {
    Invoke-Utility git merge "origin/$SourceBranchName" --ff-only -v
}
else {
    Invoke-Utility git merge "origin/$SourceBranchName" --ff-only
}

Write-Output -InputObject ""

Write-Verbose -Message "Pushing merge changes to origin of branch '$DestinationBranchName'"

if ($IsVerbose) {
    Invoke-Utility git push -v
}
else {
    Invoke-Utility git push
}

Write-Output -InputObject ""

Write-Output -InputObject "Merge complete from branch '$SourceBranchName' into branch '$DestinationBranchName'"

Write-Verbose -Message "Swapping back to original branch '$TriggerBranchName' for run safety"

Invoke-Utility git checkout $TriggerBranchName

Write-Output -InputObject ""

Write-Output -InputObject "Merge Process Complete!"

#endregion Execution
