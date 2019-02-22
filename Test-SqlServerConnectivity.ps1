<#
    .Synopsis
    Test Connectivity to SQL Server Instance

    .Description
    This script tests connectivity to a SQL Server instance. The script attempts to connect to an instance from it's host machine at a specified interval over a specified period.

    .Parameter InstanceName
    The name or IP address of the instance you're testing connectivity of.

    .Parameter PollingFrequencyInSeconds
    The number of seconds between each connectivity attempt.

    .Parameter TestDurationInSeconds
    The test's length of time expressed in seconds.

    .Example
    Test-SqlServerConnectivity.ps1 -InstanceName '(local)\ss2k12' -PollingFrequencyInSeconds 5 -TestDurationInSeconds 60

    This attempts to connect to an instance named "(local)\ss2k12" every
    5-seconds for 1-minute.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)][string]$InstanceName
  , [Parameter(Mandatory=$True,Position=2)][int]$PollingFrequencyInSeconds
  , [Parameter(Mandatory=$True,Position=3)][int]$TestDurationInSeconds
)

Set-StrictMode -Version 5.0

$database = 'tempdb'

$probe_parameters = @{
    connection_string = "Provider=sqloledb;Data Source=${InstanceName};Initial Catalog=${database};Integrated Security=SSPI;Connect Timeout=3"
}

$probe_script = {
    $ErrorActionPreference = 'Stop'

    $db_connection = New-Object -TypeName 'System.Data.OleDb.OleDbConnection' `
        -ArgumentList $event.MessageData.connection_string

    try {
        $db_connection.Open()
        $sql_statement_text = "SELECT GETDATE();"
        $sql_command = `
            New-Object -TypeName 'System.Data.OleDb.OleDbCommand' -ArgumentList $sql_statement_text, $db_connection
        $sql_command.ExecuteNonQuery() | Out-Null

        $status_update = "{0}: Connection succeeded." -f $(Get-Date -Format HH:mm:ss.ms).ToString()
    } catch {
        $status_update = "{0}: Connection failed." -f $(Get-Date -Format HH:mm:ss.ms).ToString()
    } finally {
        $db_connection.Close()
        $db_connection.Dispose()
   
        Write-Host $status_update
    }
    
}

$test_duration = New-Object 'System.Timers.Timer'
$test_duration.AutoReset = $false
$test_duration.Interval = $TestDurationInSeconds * 1000

$probe_polling_time = New-Object 'System.Timers.Timer'
$probe_polling_time.Interval = $PollingFrequencyInSeconds * 1000
$probe_polling_time.AutoReset = $True

Register-ObjectEvent -InputObject $probe_polling_time `
    -EventName Elapsed `
    -Action $probe_script `
    -MessageData $probe_parameters

Register-ObjectEvent -InputObject $test_duration `
    -EventName Elapsed `

$status_update = "{0}: Test Starting..." -f $(Get-Date -Format HH:mm:ss.ms).ToString()
Write-Host $status_update

$probe_polling_time.Start()
$test_duration.Start()

while ($probe_polling_time.Enabled -eq $True) {
    if ($test_duration.Enabled -eq $False) { $probe_polling_time.Stop() }
    Start-Sleep -Seconds 1
}

$status_update = "{0}: Test Completed..." -f $(Get-Date -Format HH:mm:ss.ms).ToString()
Write-Host $status_update