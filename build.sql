USE [master];
GO
CREATE SCHEMA [dba];
GO
CREATE TABLE dba.probe_sqlserver_connectivity (
	source_server sysname not null default(cast(serverproperty('ComputerNamePhysicalNetBIOS') AS sysname))
  , target_server sysname not null 
  , test_datetime smalldatetime not null default(getdate())
  , test_failed bit not null
)
GO
USE [msdb]
GO
/****** Object:  Job [probe_connectivity]    Script Date: 12/18/2018 6:39:49 PM ******/
BEGIN TRANSACTION
DECLARE @operator SYSNAME = suser_sname();
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 12/18/2018 6:39:49 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'probe_connectivity', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This is an administrative problem meant to identify connectivity issues.', 
		@category_name=N'Data Collector', 
		@owner_login_name=@operator,
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Execute Connection Test]    Script Date: 12/18/2018 6:39:49 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute Connection Test', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'$server_instance = @@servername
$database = ''tempdb''
$connection_string = `
    "Provider=sqloledb;Data Source=${server_instance};Initial Catalog=${database};Integrated Security=SSPI;Connection Timeout=15"

$db_connection = `
    New-Object System.Data.OleDb.OleDbConnection $connection_string

try {
    $db_connection.Open()
    $sql_statement_text = "SELECT GETDATE();"
    $sql_command = `
        New-Object System.Data.OleDb.OleDbCommand $sql_statement_text, $db_connection
    $sql_command.ExecuteNonQuery() | Out-Null
} catch [System.Data.OleDb.OleDbException] {
    throw $_.Exception
} finally {
    $db_connection.Close()
    $db_connection.Dispose()
}', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Test Succeeded]    Script Date: 12/18/2018 6:39:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Test Succeeded', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @target_server sysname = ''<servername>'';
DECLARE @probe_test_succeeded bit = 0;

INSERT INTO dba.probe_sqlserver_connectivity (target_server, test_failed)
VALUES (@target_server, @probe_test_succeeded);', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Test Failed]    Script Date: 12/18/2018 6:39:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Test Failed', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @target_server sysname = ''<servername>'';
DECLARE @probe_test_failed bit = 1;

INSERT INTO dba.probe_sqlserver_connectivity (target_server, test_failed)
VALUES (@target_server, @probe_test_failed);', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'probe_schedule_5min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181218, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


