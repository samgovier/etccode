<#
.SYNOPSIS
    Edit-RelVersion edits files in accordance with the release of a new version of this project . It updates the files and commits the changes to the trigger branch.
    There are two modes of running the script:
    - The main mode is FriendlyNameAddOn. This simply adds the provided version as the friendly name of the version for release.
    - The other mode is VersionIncrement. This updates all files with the old version in the project to the new version.

.PARAMETER VersionToSet
    VersionToSet is the version that is being added/set in the project.
    For Friendly Name, this is just the friendly name to set. For version increment, this is the next version of the project.

.PARAMETER TriggerBranchName
    TriggerBranchName is the branch that is triggering this script. This is used to pull the full branch, to keep Git operations safe.

.PARAMETER VersionIncrement
    VersionIncrement is a switch that is set to determine the script mode. If set true, we're incrementing the version of the project, not setting friendly name.

.PARAMETER OldVersion
    OldVersion is required if we are incrementing the version of the project. This is the string of the old version to find and replace with the new version.
    
.EXAMPLE
    YAML example:
    - powershell: BuildScripts/Invoke-GitMerge.ps1 -DestinationBranchName $(general-access-branch) -SourceBranchName $(early-access-branch) -TriggerBranchName $(Build.SourceBranchName) -Verbose:$$(System.Debug)
      displayName: 'Merge EA to GA'

.NOTES
    File Name       : Edit-RelVersion.ps1
    Author          : Sam Govier
    Creation Date   : 2/2/2023
#>

#region Config

[CmdletBinding(DefaultParameterSetName = "FriendlyNameAddOn")]
param (
    # VersionToSet is the version string to be set in the RMS repo files
    [Parameter(Mandatory = $true)]
    [string]
    $VersionToSet,

    # TriggerBranchName is the name of the branch this script is triggered from
    [Parameter(Mandatory = $true)]
    [string]
    $TriggerBranchName,

    # VersionIncrement is a switch that runs the script to Increment the overall version
    [Parameter(Mandatory = $true, ParameterSetName = "VersionIncrement")]
    [switch]
    $VersionIncrement,

    # OldVersion is the old version that needs to be replaced
    [Parameter(Mandatory = $true, ParameterSetName = "VersionIncrement")]
    [string]
    $OldVersion
)


# IsVerbose is a boolean that determines if the script is running in Verbose mode
$IsVerbose = ($PSBoundParameters['Verbose']) -or ($VerbosePreference -eq 'Continue')

# FRIENDLYNAME_FILEPATHS is the paths to be modified when changing the friendlyname
$FRIENDLYNAME_FILEPATHS = @('./azure-pipelines.yml')

# FRIENDLYNAME_STRING is the string to append when changing the friendlyname
$FRIENDLYNAME_STRING = "FriendlyName: '"

# FRIENDLYNAME_COMMIT_MSG is the commit message for the FriendlyName change
$FRIENDLYNAME_COMMIT_MSG = "Merged Automated FriendlyName to $VersionToSet"

# VERSION_INCREMENT_COMMIT_MSG is the commit message when incrementing version
$VERSION_INCREMENT_COMMIT_MSG = "Merged Automated Version Increment to $VersionToSet"

# VERSION_INCREMENT_FILEPATHS is the paths to be modified when incrementing version
$VERSION_INCREMENT_FILEPATHS = @(
)

# GIT_USER_EMAIL is used as email for committing to Git
$GIT_USER_EMAIL = "vsts@email.com"

# GIT_USER_NAME is used as a name for committing to Git
$GIT_USER_NAME = "Project Collection Build Service"

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

<#
.SYNOPSIS
    Test-VersionParameters takes the passed versions and tests to make sure they are formatted correctly.
    
.EXAMPLE
    Test-VersionParameters -VersionToSet $VersionToSet -OldVersion $OldVersion -VersionIncrement $VersionIncrement
#>
function Test-VersionParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $VersionToSet,

        [Parameter(Mandatory = $true)]
        [bool]
        $VersionIncrement,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $OldVersion
    )

    # Test-VersionFormat is a short internal function to run the provided versions through regex. Returns the regex match results.
    function Test-VersionFormat {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]
            $TestString
        )
        return ($TestString -match '^([0-9]+\.[0-9]+)$')
    }

    Write-Verbose -Message "Confirming Input Parameters have good formatting"

    # if VersionToSet is not formatted like a version, exit
    if (-not (Test-VersionFormat -TestString $VersionToSet)) {
        Write-Error "VersionToSet has improper version format. Format should be ##.##. Given format: $VersionToSet"
        return $false
    }

    # if we're incrementing and OldVersion is not formatted like a version, exit
    if ($VersionIncrement -and (-not (Test-VersionFormat -TestString $OldVersion))) {
        Write-Error "OldVersion has improper version format. Format should be ##.##. Given format: $OldVersion"
        return $false
    }

    # version formatting is good, return true
    return $true


}

<#
.SYNOPSIS
    Edit-FriendlyNameAddOn adds the friendly name for project release.
    
.EXAMPLE
    Edit-FriendlyNameAddOn -VersionToSet $VersionToSet
#>
function Edit-FriendlyNameAddOn {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $VersionToSet
    )

    Write-Output -InputObject "Setting the FriendlyName for release"

    # for each file in the friendlyname path, update the friendly name
    foreach ($file in $FRIENDLYNAME_FILEPATHS) {
        if (-not (Test-Path $file)) {
            throw "Filepath not found: '$file'`r`nPlease assure the filelist is correct and the script is running in the appropriate location (branch, directory, etc.)"
        }
        
        Write-Verbose -Message "Modifying '$file' to add FriendlyName"
        (Get-Content $file).Replace("$FRIENDLYNAME_STRING'", "$FRIENDLYNAME_STRING$VersionToSet'") | Set-Content $file
    }

    # commit changes to Git
    Set-ChangesToGit -CommitMessage $FRIENDLYNAME_COMMIT_MSG
}

<#
.SYNOPSIS
    Edit-VersionIncrement removes friendly name and increments the project to the next version provided.
    
.EXAMPLE
    Edit-VersionIncrement -VersionToSet $VersionToSet -OldVersion $OldVersion
#>
function Edit-VersionIncrement {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $VersionToSet,

        [Parameter(Mandatory = $true)]
        [string]
        $OldVersion
    )

    Write-Output -InputObject "Removing FriendlyName and incrementing version for next release"

    # for each file in the friendlyname path, remove the friendly name
    foreach ($file in $FRIENDLYNAME_FILEPATHS) {
        if (-not (Test-Path $file)) {
            throw "Filepath not found: '$file'`r`nPlease assure the filelist is correct and the script is running in the appropriate location (branch, directory, etc.)"
        }

        Write-Verbose -Message "Modifying '$file' to remove FriendlyName"
        (Get-Content $file).Replace("$FRIENDLYNAME_STRING$OldVersion'", "$FRIENDLYNAME_STRING'") | Set-Content $file
    }

    # for each file that needs it, increment the version
    foreach ($file in $VERSION_INCREMENT_FILEPATHS) {
        if (-not (Test-Path $file)) {
            throw "Filepath not found: '$file'`r`nPlease assure the filelist is correct and the script is running in the appropriate location (branch, directory, etc.)"
        }

        Write-Verbose -Message "Modifying '$file' to increment version"
        (Get-Content $file).Replace($OldVersion, $VersionToSet) | Set-Content $file
    }

    # commit changes to Git
    Set-ChangesToGit -CommitMessage $VERSION_INCREMENT_COMMIT_MSG
}

<#
.SYNOPSIS
    Set-ChangesToGit runs the commands to add, commit, and push changes to remote.

.EXAMPLE
    Set-ChangesToGit -CommitMessage "Update Files"
#>
function Set-ChangesToGit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $CommitMessage
    )

    # Write-Line is a short internal function to cleanup the New Line functionality
    function Write-Line {
        Write-Output -InputObject ""
    }


    Write-Output -InputObject "Committing changes to Git"

    # if we're running Verbose, print verbose info and verbose Git output
    if ($IsVerbose) {
        Write-Line
        Write-Verbose -Message "Staging changes to Git"
        Invoke-Utility git add -A -v
        Write-Line
        Write-Verbose -Message "Committing changes to local branch"
        Invoke-Utility git commit -m "$CommitMessage" -v
        Write-Line
        Write-Verbose -Message "Pushing changes to remote branch"
        Invoke-Utility git push -v
        Write-Line
    }
    # same actions as above, without verbose Git output
    else {
        Write-Line
        Invoke-Utility git add -A
        Invoke-Utility git commit -m "$CommitMessage"
        Write-Line
        Invoke-Utility git push
        Write-Line
    }
}

#endregion Functions

#region Execution

# if the version test function returns false, exit on error
if (-not (Test-VersionParameters -VersionToSet $VersionToSet -OldVersion $OldVersion -VersionIncrement $VersionIncrement)) {
    exit 1
}

Write-Verbose -Message "Set username and email for modifications"
Invoke-Utility git config --global user.email $GIT_USER_EMAIL
Invoke-Utility git config --global user.name $GIT_USER_NAME

Write-Verbose -Message "Completing explicit checkout of branch '$TriggerBranchName' for branch safety"
Invoke-Utility git checkout $TriggerBranchName
Write-Output -InputObject ""

if ($VersionIncrement) {
    Edit-VersionIncrement -VersionToSet $VersionToSet -OldVersion $OldVersion
}
else {
    Edit-FriendlyNameAddOn -VersionToSet $VersionToSet
}

Write-Output -InputObject "Edit Process Complete!"

#endregion Execution
