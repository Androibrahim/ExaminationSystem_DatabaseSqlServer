USE [ExaminationSystem]
GO

-- Daily Backup Procedure
CREATE OR ALTER PROCEDURE dbo.usp_DailyBackup
AS
BEGIN
    DECLARE @BackupPath NVARCHAR(500) = 'F:\develop\ITI dotNet Full Stack\prjects\sql Project\Backups\';
    DECLARE @FileName NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + 'ExaminationSystem_' + @CurrentDate + '.bak';
    SET @BackupName = 'ExaminationSystem-Full-' + @CurrentDate;
    
    BEGIN TRY
        BACKUP DATABASE [ExaminationSystem] 
        TO DISK = @FileName
        WITH FORMAT, INIT, NAME = @BackupName, COMPRESSION, STATS = 10;
        
        INSERT INTO CoreSystem.AuditLog (TableName, Operation, ChangedData)
        VALUES ('Database', 'BACKUP', 'File: ' + @FileName);
    END TRY
    BEGIN CATCH
        INSERT INTO CoreSystem.AuditLog (TableName, Operation, ChangedData)
        VALUES ('Database', 'BACKUP_ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- Manual Backup Procedure
CREATE OR ALTER PROCEDURE dbo.usp_ManualBackup
    @BackupType NVARCHAR(10) = 'FULL'
AS
BEGIN
    DECLARE @BackupPath NVARCHAR(500) = 'F:\develop\ITI dotNet Full Stack\prjects\sql Project\Backups\';
    DECLARE @FileName NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    
    IF @BackupType = 'FULL'
    BEGIN
        SET @FileName = @BackupPath + 'ExaminationSystem_Manual_Full_' + @CurrentDate + '.bak';
        SET @BackupName = 'ExaminationSystem-Manual-Full-' + @CurrentDate;
        BACKUP DATABASE [ExaminationSystem] TO DISK = @FileName
        WITH FORMAT, INIT, NAME = @BackupName, COMPRESSION, STATS = 10;
    END
    ELSE IF @BackupType = 'DIFF'
    BEGIN
        SET @FileName = @BackupPath + 'ExaminationSystem_Manual_Diff_' + @CurrentDate + '.bak';
        SET @BackupName = 'ExaminationSystem-Manual-Diff-' + @CurrentDate;
        BACKUP DATABASE [ExaminationSystem] TO DISK = @FileName
        WITH DIFFERENTIAL, FORMAT, INIT, NAME = @BackupName, COMPRESSION, STATS = 10;
    END
END
GO

-- SQL Server Agent Job for Daily Backup at 2:00 AM
USE [msdb]
GO

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'ExaminationSystem_DailyBackup')
    EXEC msdb.dbo.sp_delete_job @job_name = N'ExaminationSystem_DailyBackup';
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0;
DECLARE @jobId BINARY(16);

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance';

EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name=N'ExaminationSystem_DailyBackup', 
    @enabled=1, 
    @description=N'Daily automatic backup at 2:00 AM', 
    @category_name=N'Database Maintenance', 
    @owner_login_name=N'sa', 
    @job_id = @jobId OUTPUT;

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id=@jobId, 
    @step_name=N'Execute Daily Backup', 
    @step_id=1, 
    @subsystem=N'TSQL', 
    @command=N'EXEC [ExaminationSystem].[dbo].[usp_DailyBackup]', 
    @database_name=N'ExaminationSystem', 
    @retry_attempts=3, 
    @retry_interval=5;

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1;

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
    @job_id=@jobId, 
    @name=N'Daily at 2:00 AM', 
    @enabled=1, 
    @freq_type=4, 
    @freq_interval=1, 
    @active_start_time=20000;

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)';

COMMIT TRANSACTION;
GO

-- Backup History View
USE [msdb]
GO

CREATE OR ALTER VIEW dbo.vw_BackupHistory
AS
SELECT 
    bs.database_name AS DatabaseName,
    bs.backup_start_date AS BackupStartDate,
    bs.backup_finish_date AS BackupFinishDate,
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS DurationSeconds,
    CASE bs.type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Log' END AS BackupType,
    bs.backup_size / 1024 / 1024 AS BackupSizeMB,
    bs.compressed_backup_size / 1024 / 1024 AS CompressedSizeMB,
    bmf.physical_device_name AS BackupFile,
    bs.user_name AS CreatedBy
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'ExaminationSystem';
GO

PRINT 'Automatic Backup Configured Successfully!';
PRINT 'Schedule: Daily at 2:00 AM';
PRINT 'Manual Backup: EXEC [ExaminationSystem].[dbo].[usp_ManualBackup]';
PRINT 'View History: SELECT * FROM msdb.dbo.vw_BackupHistory';
GO
