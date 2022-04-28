--------------------------------------------------------------------------------- 
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
and msdb..backupset.type='D' 
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_finish_date 

--useful script

SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 3) 
--and msdb..backupset.type='L' 
and msdb.dbo.backupset.database_name='MTM'
and msdb.dbo.backupmediafamily.physical_device_name  NOT LIKE '{%'
ORDER BY 
msdb.dbo.backupset.backup_finish_date desc

-- useful script with duration


SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
DATEDIFF(MINUTE, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date)	AS duration_min,
--msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 1) 
and msdb..backupset.type='L' 
--and msdb.dbo.backupset.database_name='MTM'
and msdb.dbo.backupmediafamily.physical_device_name  NOT LIKE '{%'
ORDER BY 
duration_min desc



--backup script vlad script with speed

SELECT  @@SERVERNAME AS ServerName ,
		YEAR(backup_finish_date) AS backup_year ,
        MONTH(backup_finish_date) AS backup_month ,
        DAY(backup_finish_date)	 AS backup_day ,
        CAST(AVG(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_avg ,
        CAST(MIN(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_min ,
        CAST(MAX(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_max
FROM    msdb.dbo.backupset bset
WHERE   bset.type = 'D' /* full backups only */
        AND bset.backup_size > 1368709120 /* 5GB or larger */
        AND DATEDIFF(ss, bset.backup_start_date, bset.backup_finish_date) > 1 /* backups lasting over a second */
GROUP BY YEAR(backup_finish_date) ,
        MONTH(backup_finish_date),
        DAY(backup_finish_date)
ORDER BY @@SERVERNAME ,
        YEAR(backup_finish_date) DESC ,
        MONTH(backup_finish_date) DESC,
        DAY(backup_finish_date) DESC


---- To check compressed size as well

Declare @FromDate as datetime
-- Specify the from date value
set @FromDate = GETDATE() -1
 
SELECT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS SQLServerName, 
   msdb.dbo.backupset.database_name,  
   CASE msdb..backupset.type  
       WHEN 'D' THEN 'Database' 
       WHEN 'L' THEN 'Log' 
       WHEN 'I' THEN 'Differential' 
   END AS backup_type,  
   msdb.dbo.backupset.backup_start_date,  
   msdb.dbo.backupset.backup_finish_date, 
   msdb.dbo.backupset.expiration_date, 
   DATEDIFF (SECOND, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date) 'Backup Elapsed Time (sec)',
   msdb.dbo.backupset.compressed_backup_size AS 'Compressed Backup Size in KB',
  (msdb.dbo.backupset.compressed_backup_size/1024/1024) AS 'Compress Backup Size in MB',
   CONVERT (NUMERIC (20,3), (CONVERT (FLOAT, msdb.dbo.backupset.backup_size) /CONVERT (FLOAT, msdb.dbo.backupset.compressed_backup_size))) 'Compression Ratio',
   CASE msdb..backupset.type  
       WHEN 'D' THEN 'Database' 
       WHEN 'L' THEN 'Log' 
   END AS backup_type,  
   msdb.dbo.backupset.backup_size,  
   msdb.dbo.backupmediafamily.logical_device_name,  
   msdb.dbo.backupmediafamily.physical_device_name,   
   msdb.dbo.backupset.name AS backupset_name, 
   msdb.dbo.backupset.description 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE
CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= @FromDate
AND msdb.dbo.backupset.backup_size > 0 
ORDER BY 
   msdb.dbo.backupset.database_name, 
   msdb.dbo.backupset.backup_finish_date

---------------------------
------------------------------------------------------------------------------------------- 
--Most Recent Database Backup for Each Database 
------------------------------------------------------------------------------------------- 
SELECT  
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb..backupset.type = 'D' 
GROUP BY 
   msdb.dbo.backupset.database_name  
ORDER BY  
   msdb.dbo.backupset.database_name 



{OR}


USE [DatabaseName]
 GO
-- Get Backup History for required database
SELECT TOP 100
 s.database_name,
m.physical_device_name,
CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize,
CAST(DATEDIFF(second, s.backup_start_date,
s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
s.backup_start_date,
s.backup_finish_date,
CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
CASE s.[type] WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END AS BackupType,
s.server_name,
s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = DB_NAME()
and s.[type]='D' -- Remove this line for all the database
ORDER BY backup_start_date DESC, backup_finish_date
 GO


------------------------------------------------------------------------------------------- 
--Most Recent Database Backup for Each Database - Detailed 
------------------------------------------------------------------------------------------- 
SELECT  
   A.[Server],  
   A.last_db_backup_date,  
   B.backup_start_date,  
   B.expiration_date, 
   B.backup_size,  
   B.logical_device_name,  
   B.physical_device_name,   
   B.backupset_name, 
   B.description 
FROM 
   ( 
   SELECT   
       CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
       msdb.dbo.backupset.database_name,  
       MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
   FROM    msdb.dbo.backupmediafamily  
       INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
   WHERE   msdb..backupset.type = 'D' 
   GROUP BY 
       msdb.dbo.backupset.database_name  
   ) AS A 
    
   LEFT JOIN  

   ( 
   SELECT   
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   msdb.dbo.backupset.backup_start_date,  
   msdb.dbo.backupset.backup_finish_date, 
   msdb.dbo.backupset.expiration_date, 
   msdb.dbo.backupset.backup_size,  
   msdb.dbo.backupmediafamily.logical_device_name,  
   msdb.dbo.backupmediafamily.physical_device_name,   
   msdb.dbo.backupset.name AS backupset_name, 
   msdb.dbo.backupset.description 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb..backupset.type = 'D' 
   ) AS B 
   ON A.[server] = B.[server] AND A.[database_name] = B.[database_name] AND A.[last_db_backup_date] = B.[backup_finish_date] 
ORDER BY  
   A.database_name


----------------------------------------------

---To check for staging location


SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 1) 
and msdb..backupset.type='D'
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_finish_date 


-- Restore history


SELECT
 rh.destination_database_name AS [Database],
  CASE WHEN rh.restore_type = 'D' THEN 'Database'
  WHEN rh.restore_type = 'F' THEN 'File'
   WHEN rh.restore_type = 'I' THEN 'Differential'
  WHEN rh.restore_type = 'L' THEN 'Log'
    ELSE rh.restore_type 
 END AS [Restore Type],
 rh.restore_date AS [Restore Date],
 bmf.physical_device_name AS [Source], 
 rf.destination_phys_name AS [Restore File],
  rh.user_name AS [Restored By]
FROM msdb.dbo.restorehistory rh
 INNER JOIN msdb.dbo.backupset bs ON rh.backup_set_id = bs.backup_set_id
 INNER JOIN msdb.dbo.restorefile rf ON rh.restore_history_id = rf.restore_history_id
 INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
ORDER BY rh.restore_history_id DESC
GO