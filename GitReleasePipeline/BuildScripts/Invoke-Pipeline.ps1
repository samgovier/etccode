<#
.SYNOPSIS
    Invoke-Pipeline interacts with and waits synchronously for RMS Pipelines to run.
    It also tags the release version in Git when running on staging.
    There are two modes of running the script:
    - The release mode is run with the release switch. This explicitly initiates a release run and waits for it to finish.
    - The main mode is staging mode. This checks for the most recent staging run on the specified branch, and waits for it to finish.
    
.PARAMETER PipelineID
    PipelineID is the ID of the pipeline to interact with, generally the release or the staging pipeline.

.PARAMETER AccessToken
    AccessToken is the "user:token" combo used for Basic REST API authentication to Azure DevOps.

.PARAMETER TriggerBranchName
    TriggerBranchName is the name of the branch that is triggering the script. This is used to pull the full branch, to keep Git operations safe.

.PARAMETER PipelineBuildWaitRetry
    PipelineBuildWaitRetry is the number of minutes to wait for the pipeline to finish.

.PARAMETER PipelineBuildBranch
    PipelineBuildBranch is the branch to wait for and pull a release version from. Default is "main".

.PARAMETER ProjectName
    ProjectName is the name of the ADO project to use on the REST API.

.PARAMETER Release
    Release is a switch that specifies whether to run in release mode. This mode will actually initiate the release pipeline run and wait for it to finish.

.EXAMPLE
    YAML example:
    - powershell: BuildScripts/Invoke-Pipeline.ps1 -PipelineId $(staging-pipeline-id) -AccessToken "$(Agent.Name):$(System.AccessToken)" -TriggerBranchName $(Build.SourceBranchName) -ProjectName "DevOps" -PipelineBuildBranch $(Build.SourceBranchName) -Verbose:$$(System.Debug)
      displayName: "Wait For Build & Tag Release"


.NOTES
    File Name       : Invoke-Pipeline.ps1 (previously Invoke-GitTag.ps1)
    Author          : Sam Govier
    Creation Date   : 2/8/2023
    Changes         : 3/28/2023 : Rewrite to accomodate Release Pipeline Runs

#>

#region Config

[CmdletBinding()]
param (
    # PipelineId is the ID of the pipeline to interact with for RMS Build
    [Parameter(Mandatory = $true)]
    [string]
    $PipelineId,

    # AccessToken is the Personal Access Token used to access the ADO API
    [Parameter(Mandatory = $true)]
    [string]
    $AccessToken,

    # TriggerBranchName is the name of the branch this script is triggered from
    [Parameter(Mandatory = $true)]
    [string]
    $TriggerBranchName,

    # PipelineBuildWaitRetry is the number of minutes to wait for the pipeline to finish
    [Parameter(Mandatory = $false)]
    [int]
    $PipelineBuildWaitRetry = 25,

    # PipelineBuildBranch is the branch to pull the staging pipeline build from
    [Parameter(Mandatory = $false)]
    [string]
    $PipelineBuildBranch = "main",

    # ProjectName is the name of the Azure DevOps project where the pipeline resides
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

    # Release is a switch specifying whether to run in release mode
    [Parameter(Mandatory = $false)]
    [switch]
    $Release
)

# IsVerbose is a boolean that determines if the script is running in Verbose mode
$IsVerbose = ($PSBoundParameters['Verbose']) -or ($VerbosePreference -eq 'Continue')

# https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/pipelines/get
# API_PIPELINE_URL is the request URL for getting information on pipeline runs
$API_PIPELINE_URL = "https://dev.azure.com/subscription/$ProjectName/_apis/pipelines/$PipelineId/runs"

# API_VERSION is the version of the REST API to use
$API_VERSION = "7.0"

# API_URL_PARAMETERS creates the ending string to append at the end of the GET URL.
$API_URL_PARAMETERS = "?api-version=$API_VERSION"

# AUTH_HEADER is the Basic Authorization header used to authenticate the REST request
$AUTH_HEADER = [ordered]@{
    'Authorization' = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($AccessToken)))"
}

#endregion Config

#region Functions

<#
.SYNOPSIS
    Invoke-RMSBuildPipeline starts the release pipeline then waits for it to finish.
.EXAMPLE
    Invoke-RMSBuildPipeline -ApiPipelineUrl $API_PIPELINE_URL -ApiParameters $API_URL_PARAMETERS -AuthHeader $AUTH_HEADER -PipelineBuildWaitRetry $PipelineBuildWaitRetry -PipelineBuildBranch $PipelineBuildBranch
#>
function Invoke-RMSBuildPipeline {
    [CmdletBinding()]
    param(
        # ApiPipelineUrl is the URL for accessing pipeline runs
        [Parameter(Mandatory = $true)]
        [string]
        $ApiPipelineUrl,

        # ApiParameters is the postfix for the URL for custom parameters
        [Parameter(Mandatory = $true)]
        [string]
        $ApiParameters,

        # AuthHeader is the header used to authenticate to the API
        [Parameter(Mandatory = $true)]
        $AuthHeader,

        # PipelineBuildWaitRetry is the number of minutes to wait for the pipeline to finish
        [Parameter(Mandatory = $true)]
        [int]
        $PipelineBuildWaitRetry,

        # PipelineBuildBranch is the branch to pull the pipeline build from
        [Parameter(Mandatory = $true)]
        [string]
        $PipelineBuildBranch
    )

    Write-Output -InputObject "Running release pipeline..."
    $requestResult = Invoke-RMSPipelineRest -Uri "$ApiPipelineUrl$ApiParameters" -Method "Post" -Body "{resources:{repositories:{self:{refName:'refs/heads/$PipelineBuildBranch'}}}}" -Headers $AuthHeader
    
    Write-Output -InputObject "Waiting for release pipeline to finish..."
    Wait-PipelineFinish -ApiPipelineUrl $ApiPipelineUrl -PipelineRunID $requestResult.id -ApiParameters $ApiParameters -AuthHeader $AuthHeader -PipelineBuildWaitRetry $PipelineBuildWaitRetry
}

<#
.SYNOPSIS
    Get-RMSStagePipeline pulls the most recent staging pipeline run for the build branch, waits for it to finish, and then uses that version to create a git tag.
.EXAMPLE
    Get-RMSStagePipeline -ApiPipelineUrl $API_PIPELINE_URL -ApiParameters $API_URL_PARAMETERS -AuthHeader $AUTH_HEADER -PipelineBuildWaitRetry $PipelineBuildWaitRetry -PipelineBuildBranch $PipelineBuildBranch
#>
function Get-RMSStagePipeline {
    [CmdletBinding()]
    param(
        # ApiPipelineUrl is the URL for accessing pipeline runs
        [Parameter(Mandatory = $true)]
        [string]
        $ApiPipelineUrl,

        # ApiParameters is the postfix for the URL for custom parameters
        [Parameter(Mandatory = $true)]
        [string]
        $ApiParameters,

        # AuthHeader is the header used to authenticate to the API
        [Parameter(Mandatory = $true)]
        $AuthHeader,

        # PipelineBuildWaitRetry is the number of minutes to wait for the pipeline to finish
        [Parameter(Mandatory = $true)]
        [int]
        $PipelineBuildWaitRetry,

        # PipelineBuildBranch is the branch to pull the pipeline build from
        [Parameter(Mandatory = $true)]
        [string]
        $PipelineBuildBranch
    )

    Write-Output -InputObject "Waiting 60 seconds to allow build to begin..."
    Start-Sleep -Seconds 60

    Write-Output -InputObject "Waiting for staging pipeline to finish..."

    # runID will be the ID of the specific staging pipeline run we're waiting for
    $runID = -1

    # pipelineRunData will contain the payload of the pipeline run REST request
    $pipelineRunData = ""

    Write-Verbose -Message "Requesting run information on the Staging Pipeline"
    $pipelineRunList = Invoke-RMSPipelineRest -Uri "$ApiPipelineUrl$ApiParameters" -Headers $AuthHeader -Method "Get"

    # runCheckMax is the number of runs to check before failing out
    $runCheckMax = (@(20, $pipelineRunList.value.Count) | Measure-Object -Minimum).Minimum

    # check the top of the runlist for the pipeline and pull the latest run on PipelineBuildBranch
    for ($i = 0; $i -lt $runCheckMax; $i++) {
        $runID = $pipelineRunList.value[$i].id

        Write-Verbose -Message "Checking run $runID"
        $pipelineRunData = Invoke-RMSPipelineRest -Uri "$ApiPipelineUrl/$runID$ApiParameters" -Headers $AuthHeader -Method "Get"

        Write-Verbose -Message "Branch name for run $runID is $($pipelineRunData.resources.repositories.self.refName)"
        if ($pipelineRunData.resources.repositories.self.refName -eq "refs/heads/$PipelineBuildBranch") {
            break
        }
        else {
            $runID = -1
        }
    }

    if ($runID -eq -1) {
        throw "A run on the $PipelineBuildBranch branch for the Staging pipeline was not found. Please assure that a new build is available."
    }

    Write-Verbose -Message "Pulling full version for tagging"
    $newFullVersion = $pipelineRunData.name.Substring(0, ($pipelineRunData.name.LastIndexOf(".")))

    Wait-PipelineFinish -ApiPipelineUrl $ApiPipelineUrl -PipelineRunID $runID -ApiParameters $ApiParameters -AuthHeader $AuthHeader -PipelineBuildWaitRetry $PipelineBuildWaitRetry

    # attempt to set the version tag
    Set-GitVersionTag -ReleaseVersion $newFullVersion
}

<#
.SYNOPSIS
    Wait-PipelineFinish takes in a pipeline run and waits for the allotted time to finish successfully. If the wait times out or the pipeline fails, this function throws an error.
.EXAMPLE
    Wait-PipelineFinish -ApiPipelineUrl $ApiPipelineUrl -PipelineRunID $runID -ApiParameters $ApiParameters -AuthHeader $AuthHeader -PipelineBuildWaitRetry $PipelineBuildWaitRetry
#>
function Wait-PipelineFinish {
    [CmdletBinding()]
    param(
        # ApiPipelineUrl is the URL for accessing pipeline runs
        [Parameter(Mandatory = $true)]
        [string]
        $ApiPipelineUrl,

        # PipelineRunID is the ID of the run to wait for
        [Parameter(Mandatory = $true)]
        [string]
        $PipelineRunID,

        # ApiParameters is the postfix for the URL for custom parameters
        [Parameter(Mandatory = $true)]
        [string]
        $ApiParameters,

        # AuthHeader is the header used to authenticate to the API
        [Parameter(Mandatory = $true)]
        $AuthHeader,

        # PipelineBuildWaitRetry is the number of minutes to wait for the pipeline to finish
        [Parameter(Mandatory = $true)]
        [int]
        $PipelineBuildWaitRetry
    )

    Write-Verbose -Message "Waiting for pipeline run $PipelineRunID to finish..."

    for ($i = 0; $i -le $PipelineBuildWaitRetry; $i++) {
        $pipelineRunData = Invoke-RMSPipelineRest -Uri "$ApiPipelineUrl/$PipelineRunID$ApiParameters" -Headers $AuthHeader -Method "Get"

        # if run is completed, return success if run finished successfully
        if ($pipelineRunData.state -eq "completed") {
            if ($pipelineRunData.result -ne "succeeded") {
                throw "The run did not complete successfully. Result: $($pipelineRunData.result). Please investigate pipeline failure."
            }
            else {
                return
            }
        }

        # break if we've retried all times, we don't want to sleep again
        if ($i -eq $PipelineBuildWaitRetry) {
            break
        }

        Write-Verbose -Message "Build not complete. Waiting 1 minute ($($i + 1)/$PipelineBuildWaitRetry)..."
        Start-Sleep -Seconds 60
    }

    # run did not complete in alloted time, return an error
    throw "The run did not complete in the allotted time: $PipelineBuildWaitRetry Minutes. Please assure the build pipeline is functional or extend the timeout."
}

<#
.SYNOPSIS
    Invoke-RMSPipelineRest is a wrapper for Invoke-RestMethod that only allows the specific methods for this script, and provides better information in the case of a failure or verbose run.
.EXAMPLE
    Invoke-RMSPipelineRest -Uri $ApiPipelineUrl -Headers $AuthHeader -Method "Get"
#>
function Invoke-RMSPipelineRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [Parameter(Mandatory = $true)]
        $Headers,

        [Parameter(Mandatory = $true)]
        [string]
        $Method,

        [Parameter(Mandatory = $false)]
        [string]
        $Body
    )

    Write-Verbose -Message "Performing $Method request to: $Uri"
    if ($Method -eq "Post") {
        $result = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -Body $Body -ContentType "application/json" -StatusCodeVariable "statusCode"
    }
    else {
        $result = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -StatusCodeVariable "statusCode"
    }

    if ($statusCode -ne 200) {
        Write-Verbose -Message "Request: `r`n$Uri"
        Write-Verbose -Message "Result: `r`n$result"
        throw "$Method Request Returned Status Code $statusCode. Expected 200."
    }

    return $result
}

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
    Set-GitVersionTag adds and pushes a tag to the current repository using the release syntax.

.EXAMPLE
    Set-GitVersionTag -ReleaseVersion "22.3.15"
#>
function Set-GitVersionTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ReleaseVersion
    )

    Write-Output -InputObject "Tagging new build with release tag"
    Invoke-Utility git tag release-$ReleaseVersion

    if ($IsVerbose) {
        Write-Verbose -Message "Pushing new tag to remote"
        Invoke-Utility git push origin release-$ReleaseVersion -v
        Write-Output -InputObject ""
    }
    else {
        Invoke-Utility git push origin release-$ReleaseVersion
        Write-Output -InputObject ""
    }

}

#endregion Functions

#region Execution

Write-Verbose -Message "Completing explicit checkout of branch '$TriggerBranchName' for branch safety"
Invoke-Utility git checkout $TriggerBranchName
Write-Output -InputObject ""

if ($Release) {
    Invoke-RMSBuildPipeline -ApiPipelineUrl $API_PIPELINE_URL -ApiParameters $API_URL_PARAMETERS -AuthHeader $AUTH_HEADER -PipelineBuildWaitRetry $PipelineBuildWaitRetry -PipelineBuildBranch $PipelineBuildBranch
}
else {
    Get-RMSStagePipeline -ApiPipelineUrl $API_PIPELINE_URL -ApiParameters $API_URL_PARAMETERS -AuthHeader $AUTH_HEADER -PipelineBuildWaitRetry $PipelineBuildWaitRetry -PipelineBuildBranch $PipelineBuildBranch
}

Write-Output -InputObject "Pipeline Process Complete!"

#endregion Execution