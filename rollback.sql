USE [master];
GO
drop table dba.probe_sqlserver_connectivity;
drop schema dba;
GO
USE [msdb];
GO
EXEC sp_delete_job @job_name = N'probe_connectivity_p-db08';
GO