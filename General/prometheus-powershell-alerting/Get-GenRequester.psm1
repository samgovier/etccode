<#
.SYNOPSIS
    This PowerShell module extends DBSelect.js, using passed parameters to make a request that returns relevant data.

    That data can be output in any of 5 types: raw, PowerShell object, CSV, JSON, XML.

.PARAMETER Table
    Table is the name of the table in the db to request data from

.PARAMETER Filter
    Filter is the LDAP-formatted filter on what data is requested from the database

.PARAMETER Attributes
    Attributes is the relevant data requested (ie. columns needed from the database)

.PARAMETER SortOrder
    SortOrder is the way in which the data should be sorted. It is optional.
    This should be formatted as "attribute ASC/DESC", where attributes is what to sort by (eg. startdatetime),
      and ASC or DESC is Ascending or Descending.

.PARAMETER FastSearch
    FastSearch specifies whether to use FastSearch when running DBSelect.js. Default is 0, which is "true".
    It is optional.

.PARAMETER OutputType
    OutputType is how the data should be returned: raw, Powershell object, CSV, JSON, XML. It is optional: default is PowerShell object.

.PARAMETER PathToDBSelect
    PathToDBSelect is an optional parameter to specify where the DBSelect.js script lives.
    Default is "C:\Scripts\DBSelect.js".

.OUTPUTS
    The output of this script is variable, depending on the OutputType parameter: either a PowerShell object, CSV, JSON, XML, or raw.

.EXAMPLE
    Get-GenRequester -Table "CD" -Filter "(ID=*****)" -Attributes "state,ID,mainaccountid" -OutputType "raw"

.EXAMPLE
    Get-GenRequester -Table "PURGE" -Filter "(&(DISPLAYNAME=*)(ACTION=*))" -Attributes "*" -OutputType "csv" -SortOrder "startdatetime DESC"

.NOTES
    File Name       :   Get-GenRequester.psm1
    Author          :   Sam Govier
    Creation Date   :   08/26/20
    Versions        :   3.0.0 [SG] FT-025578
                        2.1.1 [WB] Added Get-ValueDBmanage funtion to query the database via DBSelect.js
                            and return this data in the desired format
                        2.1.0 [RBT] Updated PrometheusInstance -> prometheusInstanceName.
                            Removing Labels in favor of prometheusMetricsBase/Suffix
                        2.0.1 [RBT] Added several "ToLower" modifications to labels 
                            and prometheus metrics to increase consistency in prometheus data
                        2.0.0 [RBT] Deployed and running for purge monitoring. 
                        1.0 [RBT] Script Creation/Testing                       
#>
function Get-GenRequester
{
    # region Config

    [CmdletBinding()]
    param (
        # Table is the name of the table to request data from
        [Parameter(Mandatory=$true)]
        [string]
        $Table,

        # Filter is the LDAP-formatted filter applied to data requested from the database
        [Parameter(Mandatory=$true)]
        [string]
        $Filter,

        #Attributes are the relevant metrics (ie. columns) requested from the database
        [Parameter(Mandatory=$true)]
        [string[]]
        $Attributes,

        # OutputType is the type of data to send upon returning the function
        [Parameter(Mandatory=$false)]
        [ValidateSet("Raw","Json","Csv","Xml","Obj")]
        $OutputType = "Obj",

        # SortOrder is the way in which the data should be sorted
        [Parameter(Mandatory=$false)]
        [string]
        $SortOrder = "",

        # FastSearch specifies whether to use FastSearch when requesting from the database
        [Parameter(Mandatory=$false)]
        [uint32]
        $FastSearch = 0,

        # PathToDBSelect is the path to the DBSelect.js script
        [Parameter(Mandatory=$false)]
        [string]
        $PathToDBSelect = "C:\Scripts\DBSelect.js"
    )


    # if we're not in a 32-bit command prompt, throw an error. This script requires 32-bit
    if([Environment]::Is64BitProcess) {
        throw "Invalid process type. Please use 32-bit instead of 64-bit."
    }

    # throw an error if the script is unreachable
    if(-not (Test-Path $PathToDBSelect -PathType Leaf)) {
        throw ("The DBSelect script could not be found. " +
            "Please ensure it is reachable by the script: $PathToDBSelect")
    }

    # SortOrderFlag and FastSearchFlag are the strings to be passed to DBSelect.js regarding the passed specs
    $SortOrderFlag  = "/sort=$SortOrder"
    $FastSearchFlag = "/options=FastSearch=$FastSearch"

    # conjoin the Attributes array into a single comma-separated string; remove 'key' as it is automatic and shouldn't be duplicated
    $attrStr = ($Attributes | Where-Object -FilterScript { $PSItem -notmatch "^key$" }) -join ","
    
    # endregion Config

    # region Execution

    # perform the cscript DBSelect.js request with specified parameters
    # all requests use /csvonly at the end so the data is returned in a manageable format
    Write-Verbose -Message "Performing DBSelect.js request..."
    [System.Collections.ArrayList]$DBResult = cscript $PathToDBSelect $Table.ToUpper() $Filter $attrStr $SortOrder $FastSearchFlag "/csvonly"

    # if raw is requested, simply return
    if ($OutputType -eq "Raw") {
        return $DBResult
    }

    Write-Verbose -Message "Cleaning the raw results..."
    # remove the cscript header and other items that aren't csv rows
    $DBResult.RemoveRange(0,4)
    # add a header for the key and all attributes
    $DBResult.Insert(0, "key,$attrStr")
    # take the now well-formatted CSV and convert it into a PS object
    $DBResult = ($DBResult | ConvertFrom-Csv -Delimiter ",")

    Write-Verbose -Message "Converting the results to the desired output..."
    switch($OutputType)
    {
        'Csv' {
            return ($DBResult | ConvertTo-Csv)
        }
        'Json' {
            return ($DBResult | ConvertTo-Json)
        }
        'Xml' {
            return ($DBResult | ConvertTo-Xml)
        }
        Default {
            return $DBResult
        }
    }

    # endregion Execution
}

<#
.SYNOPSIS
    This function gets metrics from the Purge table in the database using specified parameters.

.PARAMETER StartDateTime
    StartDateTime is the earliest date to collect data from, up until the current time.
    It needs to be formatted using yyyy-MM-dd.

.PARAMETER MetricsToCollect
    MetricsToCollect is a string array of attributes (ie. columns) to pull from the Purge table.

.PARAMETER PurgeActions
    PurgeActions defines which actions to pull from the database. It's optional: default is all (*).

.PARAMETER TransportsToMonitor
    TransportsToMonitor defines which transports to pull from the database. It's optional: default is all (*).

.PARAMETER SortOrder
    SortOrder is the way in which the data should be sorted. It is optional: default is "startdatetime DESC"
    This should be formatted as "attribute ASC/DESC", where attributes is what to sort by (eg. startdatetime),
      and ASC or DESC is Ascending or Descending.

.PARAMETER OutputType
    OutputType is how the data should be returned: raw, Powershell object, CSV, JSON, XML. It is optional: default is PowerShell object.

.OUTPUTS
    The output of this script is variable, depending on the OutputType parameter: either a PowerShell object, CSV, JSON, XML, or raw.

.EXAMPLE
    $purgeTableMetricParams = @{
        StartDateTime       = $START_DATETIME
        MetricsToCollect    = $METRICS_TO_COLLECT
        PurgeActions        = $PURGE_ACTIONS
        TransportsToMonitor = $TRANSPORTS_TO_MONITOR
    }
    Get-PurgeTableMetrics @purgeTableMetricParams

.EXAMPLE
    Get-PurgeTableMetrics -StartDateTime "2022-02-25" -MetricsToCollect ('enddatetime','startdatetime') -OutputType "raw"

.NOTES
    File Name       :   Get-GenRequester.psm1
    Author          :   Sam Govier
    Creation Date   :   08/26/20
    Versions        :   3.0.0 [SG] FT-025578
                        2.0 [RBT] Deployed, testing finalized for purge monitoring. 
                        1.0 [RBT] Script Creation/Testing
#>
function Get-PurgeTableMetrics
{
    # region Config

    [CmdletBinding()]
    param (
        # StartDateTime is the earliest date to collect data from
        [Parameter(Mandatory=$true)]
        [string]
        $StartDateTime,

        # MetricsToCollect is a string array of the attributes (ie. columns) to pull from the Purge table
        [Parameter(Mandatory=$true)]
        [string[]]
        $MetricsToCollect,

        # PurgeActions is the purge action types to pull from the database
        [Parameter(Mandatory=$false)]
        [string[]]
        $PurgeActions = "*",

        # TransportsToMonitor is the transports being purged to pull from the database
        [Parameter(Mandatory=$false)]
        [string[]]
        $TransportsToMonitor = "*",

        # SortOrder is the way in which the data should be sorted
        [Parameter(Mandatory=$false)]
        [string]
        $SortOrder = "startdatetime DESC",

        # OutputType is the type of data to send upon returning the function
        [Parameter(Mandatory=$false)]
        [ValidateSet("Raw","Json","Csv","Xml","Obj")]
        $OutputType = "Obj"
    )
    # endregion Config

    # region Execution

    # formatting the desired actions to LDAP-like options
    for ($i = 0; $i -lt $PurgeActions.Count; $i++) {
        $PurgeActions[$i] = "(ACTION=$($PurgeActions[$i]))"
    }
    $ActionsFilter = $PurgeActions -join ''

    # formatting the desired transports to LDAP-like options
    for ($i = 0; $i -lt $TransportsToMonitor.Count; $i++) {
        $TransportsToMonitor[$i] = "(RECIPIENTNAME=$($TransportsToMonitor[$i]))"
    }
    $TransportsFilter = $TransportsToMonitor -join ''

    Write-Verbose -Message "Sending the formatted purge details to DBSelect.js..."
    return (Get-GenRequester -Table "PURGE" -Filter "(&(|$TransportsFilter)(|$ActionsFilter)(STARTDATETIME>=$StartDateTime))" -Attributes $MetricsToCollect -OutputType $OutputType -SortOrder $SortOrder)

    # endregion Execution
}