<#
.SYNOPSIS
    This script pulls Purge metrics from the database on a collection of Transports and Actions to send that data to the Prometheus server.

    Most parameters for this script are baked in, as it is meant to be run as an Scheduled Task. There is one parameter for debugging to output (such as command-line interface).

    This file is deployed and it's usage is configured via the `edp_genrequester` cookbook in Chef. Any deployment or powershell changes should be completed there.

.PARAMETER Role
    Role is the string denoting the server role; used for distinguishing between different database types (eg. as v. rs servers)

.PARAMETER DebugToOutput
    DebugToOutput is a switch that sends all collected data to the command-line, instead of to the Prometheus server.

.INPUTS
    Besides the debug switch.

.EXAMPLE
    When debugging:
    .\Monitor_Purge.ps1 -DebugToOutput -Verbose

.NOTES
    File Name       :   Monitor_Purge.ps1
    Author          :   Sam Govier
    Creation Date   :   08/26/20
    Versions        :   3.0.0 [SG] FT-025578
                        2.0 [RBT] Deployed, testing finalized for purge monitoring. 
                        1.0 [RBT] Script Creation/Testing
#>

# region Config

[CmdletBinding()]
param (
    # Role is the string denoting the server role; used for distinguishing between different database types (eg. as v. rs servers)
    [Parameter(Mandatory=$false)]
    [string]
    $Role = "as",

    # DebugToOutput writes all collected data to output (eg. CLI) instead of Prometheus
    [Parameter(Mandatory=$false)]
    [switch]
    $DebugToOutput
)

# START_DATETIME is the earliest datetime to collect on purge metrics
$START_DATETIME = (Get-Date).AddDays(-21).ToString("yyyy-MM-dd")

# TRANSPORTS_TO_MONITOR is an array of transports to use for purge metrics
$TRANSPORTS_TO_MONITOR = @(
    'CD','CF','CL','SM','PU','WP','AUD',
    'MOD','SOD','ISM','FTP','USF','IAS2','SMS','GARC',
    'EFFN','IFTP','FGFAXIN'
)

# PURGE_ACTIONS is an array of actions to use for purge metrics
$PURGE_ACTIONS = @(
    'COMPRESSRECORDS',
    'PURGEFILES',
    'PURGERECORDS',
    'PURGEVLA'
)

# METRICS_TO_COLLECT is an array of attributes that we need for purge metrics
$METRICS_TO_COLLECT = @(
    'action',
    'recipientname',
    'enddatetime',
    'startdatetime',
    'activitydatetime'
)

# PROM_JOB_NAME is the name of the job for the Prometheus push
$PROM_JOB_NAME = "genrequesterframework"

# PROM_INSTANCE_NAME is the instances that these metrics are for
$PROM_INSTANCE_NAME = "Monitor_purge"

# PROM_METRIC_BASE is the metric base these metrics are for
$PROM_METRIC_BASE = "edp_purge"

# endregion Config

# region Execution

Write-Verbose -Message "Importing the Get-GenRequester module..."
Import-Module Get-GenRequester -Force
Import-Module Push-ToPushgateway -Force

Write-Verbose -Message "Requesting Purge Table Metrics via GetValueDBManage.js..."
$purgeTableMetricParams = @{
    StartDateTime       = $START_DATETIME
    MetricsToCollect    = $METRICS_TO_COLLECT
    PurgeActions        = $PURGE_ACTIONS
    TransportsToMonitor = $TRANSPORTS_TO_MONITOR
}
$purgeResults = Get-PurgeTableMetrics @purgeTableMetricParams

# for each transport and action on that transport send metrics to Prometheus
foreach($transport in $TRANSPORTS_TO_MONITOR) {
    foreach($action in $PURGE_ACTIONS) {

        # for writing to Output, write a header
        if($DebugToOutput) {
            Write-Output -InputObject "$action on $transport`r`n==========="
        }

        Write-Verbose -Message "Filtering on action, transport, most recent result..."
        $currentResults = ($purgeResults | Where-Object -FilterScript { ($PSItem.action -eq $action) -and ($PSItem.recipientname -eq $transport) })
        $mostRecentResult = ($currentResults | Sort-Object -Property startdatetime -Descending | Select-Object -First 1)

        # if there are no results, move on
        if($null -eq $mostRecentResult) {
            continue
        }

        # for each metric in most recent result, Push data to the Push Gateway
        foreach($metric in $METRICS_TO_COLLECT) {

            # we don't care about the action or recipientname as metrics
            if(($metric -eq "action") -or ($metric -eq "recipientname")) {
                continue
            }

            # for writing to Output, write the metric and value
            if($DebugToOutput) {
                Write-Output -InputObject "$metric = $($mostRecentResult.$metric)"
                continue
            }

            Write-Verbose -Message "Pushing to Push Gateway: $action on $transport, $metric metric"
            $pushGatewayParams = @{
                prometheusJobName       = $PROM_JOB_NAME
                prometheusMetricsBase   = $PROM_METRIC_BASE
                prometheusInstanceName  = $PROM_INSTANCE_NAME
                prometheusMetricsSufix  = $metric
                prometheusMetricValue   = $mostRecentResult.$metric
                tableLabelValue         = @{
                    transport   = $transport
                    action      = $action
                    role        = $Role
                }
            }
            Push-ToPushgateway @pushGatewayParams
        }

        # for writing to Output, write an empty line between each row
        if($DebugToOutput) {
            Write-Output -InputObject ""
        }
    }
}

# endregion Execution