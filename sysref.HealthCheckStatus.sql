-- DROP TABLE IF EXISTS [sysref].[HealthCheckStatus]

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'sysref')
    EXEC('CREATE SCHEMA sysref AUTHORIZATION dbo')
GO

CREATE TABLE [sysref].[HealthCheckStatus] (
	[HealthCheckStatusID] INT NOT NULL
	,[Description] NVARCHAR(100) NOT NULL
    ,[ColorHex] CHAR(7) NULL
	,CONSTRAINT [PK_HealthCheckStatus] PRIMARY KEY CLUSTERED (HealthCheckStatusID ASC)
)
GO


; WITH ins
AS
(
	SELECT		0 AS HealthCheckStatusID
			,	'Not Acknowledged' AS [Description]
            ,   NULL AS [ColorHex] /* default is no color */
	
	UNION

	SELECT		1 AS HealthCheckStatusID
			,	'Confirmed Error' AS [Description]
            ,   '#E74C3C' AS [ColorHex] /* red */

	UNION

	SELECT		2 AS HealthCheckStatusID
			,	'Not an Error' AS [Description]
            ,   '#3498DB' AS [ColorHex] /* blue */

	UNION

	SELECT		3 AS HealthCheckStatusID
			,	'Needs Verification' AS [Description]
            ,   '#F39C12' AS [ColorHex] /* orange */

	UNION

	SELECT		4 AS HealthCheckStatusID
			,	'Resolved' AS [Description]
            ,   '#2ECC71' AS [ColorHex] /* green */

	UNION

	SELECT		4 AS HealthCheckStatusID
			,	'Review Exclusion List' AS [Description]
            ,   '#F39C12' AS [ColorHex] /* green */
)
INSERT		sysref.HealthCheckStatus(HealthCheckStatusID, [Description], [ColorHex])
SELECT		ins.HealthCheckStatusID
		,	ins.[Description]
		,	ins.[ColorHex]
FROM		ins
LEFT JOIN	sysref.HealthCheckStatus hcs
	ON		ins.HealthCheckStatusID = hcs.HealthCheckStatusID
WHERE		hcs.HealthCheckStatusID IS NULL
GO