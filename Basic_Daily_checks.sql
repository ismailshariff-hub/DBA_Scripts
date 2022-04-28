--Log space for specific db

DECLARE @t TABLE(DataBaseName VARCHAR(100), LogSizeMB NUMERIC(18,4), LOgPercentage NUMERIC(18,4), Status INT)
INSERT INTO @t
EXEC('DBCC sqlperf(logspace)')
select * from @t where DataBaseName='umichsandbox'

--------------------------------------------------------------------------------
--- Sp_blitz_cahce
SELECT [CheckDate]
	  ,[DatabaseName]
      ,[QueryType]
	  ,[AverageDuration]      
	  ,[AverageReads]
	  ,[AverageWrites]
	  ,[ExecutionsPerMinute]
	  ,[AverageCPU]
      --,[QueryText]
	  ,[QueryPlanCost]
,[QueryPlan]
	  ,[AverageReturnedRows]
      --,[Warnings]
      --,[SerialDesiredMemory]
      --,[SerialRequiredMemory]
      ,[TotalCPU]
      ,[PercentCPUByType]
      ,[CPUWeight]
      ,[TotalDuration]
      ,[DurationWeight]
      ,[PercentDurationByType]
      --,[TotalReads]
      --,[ReadWeight]
      --,[PercentReadsByType]
      --,[TotalWrites]
      --,[WriteWeight]
      ,[PercentWritesByType]
      ,[ExecutionCount]
      ,[ExecutionWeight]
      ,[PercentExecutionsByType]
      ,[PlanCreationTime]
      ,[PlanCreationTimeHours]
      ,[LastExecutionTime]
      ,[PlanHandle]
      ,[SqlHandle]
      --,[Remove SQL Handle From Cache]
      --,[QueryPlanHash]
      --,[StatementStartOffset]
      --,[StatementEndOffset]
      --,[MinReturnedRows]
      --,[MaxReturnedRows]
      ,[TotalReturnedRows]
      ,[NumberOfPlans]
      ,[NumberOfDistinctPlans]
      ,[MinGrantKB]
      ,[MaxGrantKB]
      ,[MinUsedGrantKB]
FROM [DBA].[dbo].[BlitzCache]
WHERE DatabaseName='umichsandbox'
and [CheckDate]>GETDATE()-1
ORDER BY [CheckDate] desc
----------------------------------------------------------------------------------------------

--errorlog query
EXEC xp_readerrorlog 0, 1, NULL, NULL, '2019-12-14 13:30:10', '2020-10-27 23:30:10', N'desc' 

--AND/OR


declare @Time_Start datetime;
declare @Time_End datetime;
set @Time_Start=getdate()-2;
set @Time_End=getdate();
-- Create the temporary table
CREATE TABLE #ErrorLog (logdate datetime
                      , processinfo varchar(255)
                      , Message varchar(500))
-- Populate the temporary table
INSERT #ErrorLog (logdate, processinfo, Message)
   EXEC master.dbo.xp_readerrorlog 0, 1, null, null , @Time_Start, @Time_End, N'desc';
-- Filter the temporary table
SELECT LogDate, Message FROM #ErrorLog
WHERE (Message LIKE '%error%' OR Message LIKE '%failed%' OR Message NOT LIKE  'CHECKDB') 
AND processinfo NOT LIKE 'logon' 
ORDER BY logdate DESC
-- Drop the temporary table 
DROP TABLE #ErrorLog
----------------------------------------------------------------------

DBCC sqlperf(logspace)--log volume
----------------------------------------------------------------------
--convert sp_who2 into var table 
declare @sp_who2 table
	(
	 spid int,
	 [status] varchar (100),
	 [login] varchar (100),
	 hostname varchar (100),
	 blkdby varchar (100),
	 dbname varchar (100),
	 cmd varchar (100),
	 cputime varchar (100),
	 diskio varchar (100),
	 lastbatch varchar (100),
	 progname varchar (100),
	 spid2 varchar (100),
	 requestid varchar (100)
	 
	 )
insert  Into @sp_who2

exec('sp_who2')
select * from @sp_who2
where spid>50
ORDER BY lastbatch DESC


DBCC INPUTBUFFER (116)


--FIND_STATMENT_BY_SPID
DECLARE @HANDLE BINARY(20)
SELECT @HANDLE = sql_handle from sys.sysprocesses where spid = 2120
SELECT text FROM ::fn_get_sql(@handle)

----------------------------------------------------------------------

--find tables physical space
create table #TempTable
(
name varchar (100),
rows varchar (100),	
reserved varchar (100),	
data varchar (100),
index_size varchar (100),
unused varchar (100)
)
Insert into #TempTable Exec sys.sp_MSforeachtable ' sp_spaceused "?" ' 

select name, SUBSTRING ( reserved , 1 , (PATINDEX ( '%KB%' , reserved) )-1)/1024/1024 as GBs
from #TempTable
order by GBs desc
drop table #TempTable
-----------------------------------

----------------------------------------------------------------------

--RESTART DATE 2008 AND HIGHER 
SELECT @@servername servername, sqlserver_start_time FROM sys.dm_os_sys_info
 
--RESTART DATE 2005
SELECT @@servername servername, create_date sqlserver_start_time FROM sys.databases WHERE name = 'tempdb'
 
--RESTART DATE 2000
SELECT crdate AS SQLStarted FROM master..sysdatabases WHERE name = 'tempdb'
 
 
--DATABASE DETAILS AS STATE/COMP_LEVEL/REC_MODEL/MDF_LDF_SIZE/CREATE_UPDATE_STATS
SELECT  @@SERVERNAME,
                                d.name DB__NAME,
                                d.state_desc,
                                d.database_id ,
                                d.compatibility_level ,
                                d.recovery_model_desc ,
                                s.[Data File(s) Size (KB)]/1024 [Data File(s) Size (MB)],
                                s.[Log File(s) Size (KB)]/1024 [Log File(s) Size (MB)] ,
                                s.[Percent Log Used] ,
                                d.is_auto_create_stats_on ,
                                d.is_auto_update_stats_on ,
                                d.is_auto_update_stats_async_on,
                                d.is_parameterization_forced
FROM sys.databases d
JOIN	(SELECT *
		FROM   (SELECT instance_name AS database_name, counter_name, cntr_value
                FROM sys.dm_os_performance_counters
                WHERE object_name like '%:Databases%' and counter_name in ('Data File(s) Size (KB)', 'Log File(s) Size (KB)', 'Percent Log Used')
                AND instance_name != '_Total') p PIVOT (min(cntr_value) for counter_name 
                IN ([Data File(s) Size (KB)], [Log File(s) Size (KB)], [Percent Log Used])) as q) as s
ON d.name = s.database_name
order by s.[Data File(s) Size (KB)] desc

--------------------------------------------------------------------------------------------------------------------------------------------

--FILES LOCATION AND DETAILS
IF EXISTS	(	SELECT  *  
				FROM tempdb.dbo.sysobjects
                WHERE     id = OBJECT_ID(N'#HoldforEachDB')
			) 
DROP TABLE #HoldforEachDB; 
CREATE TABLE #HoldforEachDB([Server] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, [DatabaseName] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS
 NOT NULL, [Size] [int] NOT NULL, [File_Status] [int] NULL, [Name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, 
[Filename] [nvarchar](260) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, [Status] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, 
[Updateability] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, [User_Access] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, 
[Recovery] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL) ON [PRIMARY]
    INSERT      
     INTO            #HoldforEachDB EXEC sp_MSForEachDB 'SELECT CONVERT(char(100), SERVERPROPERTY(''Servername'')) AS Server,
                 ''?'' as DatabaseName,[?]..sysfiles.size, [?]..sysfiles.status, [?]..sysfiles.name, [?]..sysfiles.filename,convert(sysname,DatabasePropertyEx(''?'',''Status'')) as Status,
convert(sysname,DatabasePropertyEx(''?'',''Updateability'')) as Updateability,
 convert(sysname,DatabasePropertyEx(''?'',''UserAccess'')) as User_Access,
convert(sysname,DatabasePropertyEx(''?'',''Recovery'')) as Recovery From [?]..sysfiles '

SELECT [Server],
		DatabaseName ,
		(Size*8.00/1024) Size_MB , 
		File_Status,
		[Name], 
		[Filename],
		[Status] , 
		[Updateability] ,
		[User_Access], 
		[Recovery] 
FROM #HoldforEachDB;

---------------------------------------------------------------------------------------------------------

--LOG SPACE
DECLARE @t TABLE(DataBaseName VARCHAR(100), LogSizeMB NUMERIC(18,4), LOgPercentage NUMERIC(18,4), Status INT)
INSERT INTO @t
EXEC('DBCC sqlperf(logspace)')
select * from @t



----------------------------------------------------------------------------------------------------
--the below variables are min date of collected data kept in the DB (50 days)

DECLARE @Frstdate date=dateadd(hh,-240,getdate()),
		@Recentdate date=dateadd(hh,+4,getdate());

--data grouped by date & wait_type

SELECT @@servername servername,CAST(sts.CheckDate AS DATE) AS CheckDate,
		sts.wait_type,
		sum(wait_time_minutes_delta) AS total_minutes_day,
		--LAG(sum(wait_time_minutes_delta)) OVER (ORDER BY sts.wait_type) AS wait_time_minutes_delta_diff,
		--((sum(wait_time_minutes_delta))-(LAG(sum(wait_time_minutes_delta)) OVER (ORDER BY sts.wait_type)))*-1 lag_diff,
		dsc.Wait_Type_desc
FROM [DBA].[dbo].[BlitzFirst_WaitStats_Deltas] sts
JOIN DBA.dbo.Wait_Type_Description dsc
ON sts.wait_type=dsc.Wait_type
WHERE	[CheckDate]>@Frstdate
AND		(	sts.wait_type IN 
('HADR_SYNC_COMMIT'
,'CXPACKET'
,'ASYNC_NETWORK_IO'
,'SOS_SCHEDULER_YIELD'
,'PAGEIOLATCH_SH'
,'PAGEIOLATCH_EX'
))
--AND DATENAME(dw,CheckDate) in('Saturday','sunday')
--AND  DATEPART(HOUR, CheckDate)>='01' and DATEPART(HOUR, CheckDate)<'03'
GROUP BY sts.wait_type, CAST(CheckDate AS DATE), dsc.Wait_Type_desc, servername
HAVING SUM(wait_time_minutes_delta)>10
ORDER BY sts.wait_type desc, CAST(CheckDate AS DATE) desc

--select min([CheckDate])
--FROM [DBA].[dbo].[BlitzFirst_WaitStats_Deltas]


