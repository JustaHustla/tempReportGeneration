CREATE OR ALTER PROCEDURE [dbo].[spUpdate_iODS_ActualRateGreaterThanTarget] (
	@business_lines VarcharTable READONLY
	,@startdate DATE = '2000-01-01'
	,@enddate DATE = '2999-01-01'
)
AS

/* example:

declare @business_lines VarcharTable
,@startdate date = '2025-02-01'
,@enddate date = '2025-02-05'

insert into @business_lines
select '111 - baby_care'

exec dbo.spUpdate_iODS_ActualRateGreaterThanTarget @business_lines, @startdate, @enddate

*/

DECLARE @DefaultThreshold NUMERIC(8, 2) = 1.0
	,@ReportID INT = 6;

DROP TABLE IF EXISTS #business_line_filter;

CREATE TABLE #business_line_filter (
	business_line NVARCHAR(113) NOT NULL
	);

IF NOT EXISTS (SELECT 1 FROM @business_lines)
	INSERT INTO #business_line_filter(business_line)
	SELECT DISTINCT [business_line]
	FROM dbo.iODS_Site_Line_Xref
	WHERE site_is_active = 1
	AND line_is_active = 1;
ELSE
	INSERT INTO #business_line_filter(business_line)
	SELECT DISTINCT [Value]
	FROM @business_lines;

DROP TABLE IF EXISTS #businesss_line_thresholds;

CREATE TABLE #businesss_line_thresholds (
	business_line NVARCHAR(113) NOT NULL
	,NumericValue NUMERIC(8, 2)
	);

INSERT INTO #businesss_line_thresholds (
	business_line
	,NumericValue
	)
SELECT x.business_line
	,COALESCE(l.NumericValue, d.NumericValue, s.NumericValue, b.NumericValue, @DefaultThreshold) AS NumericValue
FROM iODS_Site_Line_Xref x
JOIN dbo.ReportDefinitions rd ON rd.ReportID = @ReportID
JOIN #business_line_filter bf ON x.business_line = bf.business_line
LEFT JOIN dbo.ReportDataThresholds l ON x.line_desc = l.LineName
	AND x.dept_desc = l.Department
	AND x.site_desc = l.SiteName
	AND x.bu = l.BusinessUnit
	AND rd.ReportID = l.ReportID
	AND l.LineName IS NOT NULL
LEFT JOIN dbo.ReportDataThresholds d ON x.dept_desc = d.Department
	AND x.site_desc = d.SiteName
	AND x.bu = d.BusinessUnit
	AND rd.ReportID = d.ReportID
	AND d.LineName IS NULL
	AND d.Department IS NOT NULL
LEFT JOIN dbo.ReportDataThresholds s ON x.site_desc = s.SiteName
	AND x.bu = s.BusinessUnit
	AND rd.ReportID = s.ReportID
	AND s.Department IS NULL
	AND s.LineName IS NULL
	AND s.SiteName IS NOT NULL
LEFT JOIN dbo.ReportDataThresholds b ON x.bu = b.BusinessUnit
	AND rd.ReportID = b.ReportID
	AND b.SiteName IS NULL
	AND b.Department IS NULL
	AND b.LineName IS NULL
	AND b.BusinessUnit IS NOT NULL;

DROP TABLE IF EXISTS #excluded_pu;

CREATE TABLE #excluded_pu (
	business_line NVARCHAR(113) NOT NULL
	,pu_id INT NOT NULL
	);

INSERT INTO #excluded_pu (
	business_line
	,pu_id
	)
SELECT x.business_line
	,pu.pu_id
FROM dbo.iODS_Site_Line_Xref x
JOIN #business_line_filter b ON x.business_line = b.business_line
JOIN dbo.iODS_Business_Line_PU pu ON x.business_line = pu.business_line
JOIN dbo.ReportDataExclusions e ON x.bu = e.BusinessUnit
	AND x.line_desc = e.LineName
	AND pu.pu_desc = e.PUDesc
	AND (e.ReportID = @ReportID OR e.ReportID IS NULL);

DROP TABLE IF EXISTS #iODS_ActualRateGreaterThanTarget;

CREATE TABLE #iODS_ActualRateGreaterThanTarget (
	central_line_id INT NOT NULL
	,pl_id INT NOT NULL
	,pu_id INT NOT NULL
	,site_id INT NOT NULL
	,bu NVARCHAR(100) NOT NULL
	,start_time DATETIME NOT NULL
	,end_time DATETIME NOT NULL
	,production_day DATE NOT NULL
	,process_order VARCHAR(50) NOT NULL
	,actual_rate NUMERIC(18, 4) NULL
	,target_rate NUMERIC(18, 4) NULL
	,total_product BIGINT NOT NULL
	,scheduled_time NUMERIC(18, 4) NOT NULL
	,uptime NUMERIC(18, 4) NOT NULL
	,business_line NVARCHAR(113) NOT NULL 
	
	/* let SQL generate the PK name to avoid conflicts */
	PRIMARY KEY CLUSTERED (
		production_day ASC
		,business_line ASC
		,start_time ASC
		,central_line_id ASC
		,pl_id ASC
		,pu_id ASC
		,site_id ASC
		,bu ASC
		)
	);

INSERT INTO #iODS_ActualRateGreaterThanTarget (
	central_line_id
	,pl_id
	,pu_id
	,site_id
	,bu
	,start_time
	,end_time
	,production_day
	,process_order
	,actual_rate
	,target_rate
	,total_product
	,scheduled_time
	,uptime
	,business_line
	)
SELECT pd.central_line_id
	,pd.pl_id
	,pd.pu_id
	,pd.site_id
	,pd.bu
	,pd.start_time AS start_time
	,pd.end_time AS end_time
	,pd.production_day AS production_day
	,pd.process_order
	,pd.actual_rate
	,pd.target_rate
	,pd.total_product
	,pd.scheduled_time
	,pd.uptime
	,LTRIM(STR(pd.central_line_id)) + ' - ' + pd.bu
FROM iODS_Production_Data pd
JOIN iODS_MD_LineStatus ls ON pd.line_status = ls.line_status
JOIN #business_line_filter b ON pd.business_line = b.business_line
JOIN #businesss_line_thresholds blt ON pd.business_line = blt.business_line
WHERE pd.production_day BETWEEN @startdate AND @enddate
	AND ls.PROut = 0
	AND ISNULL(pd.actual_rate, 0) - ISNULL(pd.target_rate, 0) > blt.NumericValue
	AND pd.end_time IS NOT NULL
	AND NOT EXISTS (
		SELECT 1
		FROM #excluded_pu e
		WHERE pd.business_line = e.business_line
			AND pd.pu_id = e.pu_id
		);

DELETE tgt
FROM dbo.iODS_ActualRateGreaterThanTarget tgt
JOIN #business_line_filter b ON tgt.business_line = b.business_line
WHERE tgt.production_day BETWEEN @startdate	AND @enddate
	AND NOT EXISTS (
		SELECT 1
		FROM #iODS_ActualRateGreaterThanTarget src
		WHERE tgt.production_day = src.production_day
			AND tgt.business_line = src.business_line
			AND tgt.start_time = src.start_time
			AND tgt.central_line_id = src.central_line_id
			AND tgt.pl_id = src.pl_id
			AND tgt.pu_id = src.pu_id
			AND tgt.site_id = src.site_id
			AND tgt.bu = src.bu
		);

UPDATE tgt
SET tgt.end_time = src.end_time
	,tgt.process_order = src.process_order
	,tgt.actual_rate = src.actual_rate
	,tgt.target_rate = src.target_rate
	,tgt.total_product = src.total_product
	,tgt.scheduled_time = src.scheduled_time
	,tgt.uptime = src.uptime
FROM dbo.iODS_ActualRateGreaterThanTarget AS tgt
INNER JOIN #iODS_ActualRateGreaterThanTarget AS src 
	ON tgt.production_day = src.production_day
	AND tgt.business_line = src.business_line
	AND tgt.start_time = src.start_time
	AND tgt.central_line_id = src.central_line_id
	AND tgt.pl_id = src.pl_id
	AND tgt.pu_id = src.pu_id
	AND tgt.site_id = src.site_id
	AND tgt.bu = src.bu
WHERE EXISTS (
		SELECT src.end_time
			,src.process_order
			,src.actual_rate
			,src.target_rate
			,src.total_product
			,src.scheduled_time
			,src.uptime
		
		EXCEPT
		
		SELECT tgt.end_time
			,tgt.process_order
			,tgt.actual_rate
			,tgt.target_rate
			,tgt.total_product
			,tgt.scheduled_time
			,tgt.uptime
		);

INSERT INTO dbo.iODS_ActualRateGreaterThanTarget (
	central_line_id
	,pl_id
	,pu_id
	,site_id
	,bu
	,start_time
	,end_time
	,production_day
	,process_order
	,actual_rate
	,target_rate
	,total_product
	,scheduled_time
	,uptime
	)
SELECT central_line_id
	,pl_id
	,pu_id
	,site_id
	,bu
	,start_time
	,end_time
	,production_day
	,process_order
	,actual_rate
	,target_rate
	,total_product
	,scheduled_time
	,uptime
FROM #iODS_ActualRateGreaterThanTarget src
WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.iODS_ActualRateGreaterThanTarget tgt
		WHERE tgt.production_day = src.production_day
			AND tgt.business_line = src.business_line
			AND tgt.start_time = src.start_time
			AND tgt.central_line_id = src.central_line_id
			AND tgt.pl_id = src.pl_id
			AND tgt.pu_id = src.pu_id
			AND tgt.site_id = src.site_id
			AND tgt.bu = src.bu
		);
GO