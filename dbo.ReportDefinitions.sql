CREATE TABLE [dbo].[ReportDefinitions](
	[ReportID] [int] IDENTITY(1,1) NOT NULL,
	[ReportName] [nvarchar](150) NOT NULL,
    [SortOrder] [int] NOT NULL,
    [ReportGroupID] [int] NOT NULL,
    [TooltipText] [nvarchar](800) NULL,
    [Route] [nvarchar](200) NOT NULL,
    [Icon] [nvarchar](100) NULL,
	[TroubleshootingContent] [nvarchar](2000) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
     
    CONSTRAINT [PK_ReportDefinitions] PRIMARY KEY CLUSTERED 
    (
        [ReportID] ASC
    ),

    CONSTRAINT [NUK_ReportDefinitions_ReportName] UNIQUE NONCLUSTERED 
    (
        [ReportName] ASC
    ),

    CONSTRAINT FK_ReportDefinitions_ReportGroupID FOREIGN KEY (
		ReportGroupID
		) REFERENCES dbo.ReportGroups(ReportGroupID)
)
GO

ALTER TABLE [dbo].[ReportDefinitions] ADD  CONSTRAINT [DF_ReportDefinitions_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

ALTER TABLE [dbo].[ReportDefinitions] ADD  CONSTRAINT [DF_ReportDefinitions_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO

SET IDENTITY_INSERT [dbo].[ReportDefinitions] ON;

;WITH RD AS (
    SELECT *
    FROM (
        VALUES 
        (1,N'Negative Good Product',10,1,N'# of events in the production ETL table that have POs; line status is not PR Out and where good product count is negative (production data issue)',N'negative-good-product',N'minus-circle',N'This is a mock troubleshooting message for the "Negative Good Product" report. If you see negative good product values, double-check your filters for production days, lines, and process orders. Contact support if this persists.',1),
        (2,N'Missing Target Rate',20,1,N'# POs missing a Target Rate (null or zero in Proficy) when line status is not PR OUT',N'missing-target-rate',N'bullseye',N'This is a mock troubleshooting message for the "Missing Target Rate" report. If you see negative good product values, double-check your filters for production days, lines, and process orders. Contact support if this persists.',1),
        (3,N'iODS vs SAP Production',30,1,N'# POs where the number of cases in Proficy does not match SAP',N'iods-vs-sap-production',N'boxes',NULL,1),
        (4,N'Started Late',40,1,N'# POs that started later than scheduled in SAP',N'started-late',N'clock',NULL,1),
        (5,N'Closed Early',50,1,N'# POs that ended earlier than expected based on NPT calendar',N'blank-report',N'hourglass-end',NULL,0),
        (6,N'Actual Rate > Target Rate',60,1,N'# production records where Actual Rate > Target Rate',N'actual-rate-greater-than-target-rate',N'balance-scale-left',NULL,1),
        (7,N'Extra Target Rate Change',70,1,N'# Days where the Target Rate unexpectedly changed before/after a PO shift',N'blank-report',N'sync-alt',NULL,0),
        (8,N'Calculated Speed vs Actual Rate',80,1,N'# production records where Calc Speed differs from Actual Rate',N'calculated-speed-vs-actual-rate',N'wave-square',NULL,1),
        (9,N'Rate Utilization > 100%',90,2,N'# Days where Rate Utilization exceeded 100%',N'rate-utilization-over-100-percent',N'chart-line',NULL,1),
        (10,N'PR Scrap Loss > +/- 2%',100,2,N'# Days where Scrap Loss exceeded threshold',N'pr-scrap-loss-over-2-percent',N'recycle',NULL,1),
        (11,N'PR Rate Loss > +/- 2%',110,2,N'# Days where Rate Loss exceeded threshold',N'pr-rate-loss-over-2-percent',N'tachometer-alt',NULL,1),
        (12,N'PR > Availability',120,2,N'# Days where PR > Availability',N'pr-greater-than-availability',N'exclamation-circle',NULL,1),
        (13,N'Uptime During PR OUT',130,2,N'# Days where line had Uptime during PR OUT',N'uptime-during-pr-out',N'plug',NULL,1),
        (14,N'Good Product w/o PO',140,2,N'# Days with good product but no PO assigned',N'good-product-without-po',N'box-open',N'This is a mock troubleshooting message for the "Good Product w/o PO" report. If you see negative good product values, double-check your filters for production days, lines, and process orders. Contact support if this persists.',1),
        (15,N'Good Product during PR OUT',150,2,N'# Days with Good Product during PR-OUT status excluding projects and eo''s',N'good-product-during-pr-out',N'ban',NULL,1),
        (16,N'PO Skipped PR OUT',160,2,N'# Days where PO was skipped with PR OUT status',N'blank-report',N'calendar-times',NULL,0),
        (17,N'CILs Outside of Planned Downtime',170,3,N'CILs performed outside of planned downtime',N'blank-report',N'tools',NULL,0),
        (18,N'Error12 - PM Order vs Proficy',180,3,N'Days where Proficy PM reason does not match PM Notifications',N'blank-report',N'clipboard-check',NULL,0),
        (19,N'PR OUT Category during PR IN Line Status',190,4,N'# Events where Downtime Reason Category is PR OUT while Line Status is PR IN',N'pr-out-category-during-pr-in-line-status',N'exclamation-circle',NULL,1),
        (20,N'PR IN Category during PR OUT Line Status',200,4,N'# Events where Downtime Reason Category is PR IN while Line Status is PR OUT',N'pr-in-category-during-pr-out-line-status',N'exchange-alt',NULL,1),
        (21,N'Planned Reason vs Category',210,4,N'# Events where Planned Reason does not match Planned Category',N'planned-reason-vs-category',N'th-list',NULL,1),
        (22,N'Missing Reason Level 3+',220,4,N'# Unplanned constraint stops missing Reason Level 3',N'missing-reason-level-3',N'dice-three',NULL,1),
        (23,N'Missing Reason Level 1+',230,4,N'# Unplanned constraint stops missing Reason Level 1',N'missing-reason-level-1',N'dice-one',NULL,1),
        (24,N'Missing Fault Description',240,4,N'# Unplanned constraint stops missing Fault Description or Fault Code',N'missing-fault-description',N'ban',NULL,1),
        (25,N'Changeovers w/o Downtime',250,5,N'# Changeovers without Downtime',N'blank-report',N'exchange-alt',NULL,0),
        (26,N'CnS Coding Reused',260,5,N'# PO''s where multiple ''Constraint Not Scheduled'' codings exist',N'blank-report',N'redo',NULL,0),
        (27,N'New Defects',270,6,N'# Newly detected defects per production day',N'blank-report',N'bug',NULL,0),
        (28,N'POs w/o Unplanned Stop',280,6,N'# POs that did not have an unplanned stop',N'blank-report',N'clipboard-check',NULL,1),
        (29,N'POs w/o Unplanned Downtime',290,6,N'# POs that did not experience unplanned downtime',N'blank-report',N'stopwatch',NULL,1),
        (30,N'Duplicate Production Records',300,7,N'# Production Events where there is more than one active Line and Prod Unit record with the same Start Time',N'duplicate-production-records',N'clone',NULL,1),
        (31,N'Duplicate Downtime Records',310,7,N'# Downtime Events where there is more than one active Line and Prod Unit record with the same Start Time',N'duplicate-downtime-records',N'clock',NULL,1),
        (32,N'Line Schedule Time > 1440 min',320,7,N'# Days with Line Schedule time > 1440 minutes (24 hours) in a day',N'line-schedule-time-over-1440-min',N'calendar-alt',NULL,1),
        (33,N'PR Above 100%',330,7,N'# Days where PR exceeded 100%',N'pr-above-100-percent',N'chart-line',NULL,1),
        (34,N'Proficy Sheet Access Violations',340,8,N'Finds users with admin-level access who are not in MD role',N'blank-report',N'user-shield',NULL,0),
        (35,N'Late NPT Record Changes',350,8,N'NPT record changes made >7 days after PO start',N'blank-report',N'history',NULL,0),
        (36,N'Schedule Variations w/o Comment',360,8,N'# Event where PR OUT STNU is used w/o a corresponding downtime entry with comment',N'schedule-variations-without-comment',N'sticky-note',NULL,1),
        (37,N'Manual Changes to Production Count',370,8,N'Identifies manual edits to production counts',N'blank-report',N'edit',NULL,0),
        (38,N'Deleted & Inserted Stops',380,8,N'Detects deleted and inserted stops by users',N'blank-report',N'trash',NULL,0),
        (39,N'Manual Rate Changes',390,8,N'Detects changes to target/actual rate after run',N'blank-report',N'sliders-h',NULL,0),
        (40,N'Overlapping Production Events',400,7,N'# Production Events where the Start and End intersect with another event for the same line and prod unit',N'overlapping-production-events',N'arrows-up-to-line',NULL,1),
        (41,N'Overlapping Downtime Events',410,7,N'# Downtime Events where the Start and End intersect with another event for the same line and prod unit',N'overlapping-downtime-events',N'arrows-down-to-line',NULL,1),
        (42,N'Production End Before Start',420,7,N'# Production Events where End Time before Start Time',N'production-end-before-start',N'arrows-turn-to-dots',NULL,1),
        (43,N'Downtime End Before Start',430,7,N'# Downtime Events where End Time before Start Time',N'downtime-end-before-start',N'clock-rotate-left',NULL,1),
        (44,N'Invalid Line States',440,7,N'# Events with Invalid Line Status',N'invalid-line-states',N'times-circle',NULL,1)
    ) AS vtable 
    ([ReportID],[ReportName],[SortOrder],[ReportGroupID],[TooltipText],[Route],[Icon],[TroubleshootingContent],[IsActive])
)
MERGE dbo.ReportDefinitions AS TARGET
USING RD AS SOURCE
    ON TARGET.ReportID = SOURCE.ReportID
WHEN MATCHED THEN 
    UPDATE SET 
        TARGET.ReportName = SOURCE.ReportName,
        TARGET.TooltipText = SOURCE.TooltipText,
        TARGET.Route = SOURCE.Route,
        TARGET.Icon = SOURCE.Icon,
        TARGET.TroubleshootingContent = SOURCE.TroubleshootingContent,
        TARGET.IsActive = SOURCE.IsActive,
        TARGET.SortOrder = SOURCE.SortOrder,
        TARGET.ReportGroupID = SOURCE.ReportGroupID
WHEN NOT MATCHED BY TARGET THEN 
    INSERT (
        ReportID,
        ReportName,
        TooltipText,
        [Route],
        Icon,
        TroubleshootingContent,
        IsActive,
        CreatedAt,
        SortOrder,
        ReportGroupID
    )
    VALUES (
        SOURCE.ReportID,
        SOURCE.ReportName,
        SOURCE.TooltipText,
        SOURCE.[Route],
        SOURCE.Icon,
        SOURCE.TroubleshootingContent,
        SOURCE.IsActive,
        GETDATE(),
        SOURCE.SortOrder,
        SOURCE.ReportGroupID
    )
WHEN NOT MATCHED BY SOURCE THEN 
	DELETE;

SET IDENTITY_INSERT [dbo].[ReportDefinitions] OFF;
