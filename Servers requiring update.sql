SET NOCOUNT ON

-- get a summary where machines registered in SCCM are currently requiring updates to be installed
SELECT
		VS.Name0 AS [Machine Name]
		,ISNULL(CountOfUpdates,0) AS [Updates Required]
		,X.FirstUpdateRequired
		-- we have a naming standard, so I can work out the Owner based on the name
		,CASE
			WHEN VS.Name0 LIKE 'XX%' THEN ''
			Else '' 
		END AS [Owner]
		-- here the naming convention helps too
		,CASE
			WHEN VS.Name0 LIKE 'XX%' Then 'Prod' 
			WHEN VS.Name0 LIKE 'YY%' THEN 'Non-Prod'
			ELSE ''
		END AS [Type]
		,VS.Operating_System_Name_and0 as [OS]
		,VS.User_Name0 AS [Primary User]
		,VS.Last_Logon_Timestamp0 AS [LastLogon]
		,Y.[Collection Name]
		,CASE WHEN Operating_System_Name_and0 LIKE '%Server%' THEN 'Server' ELSE 'Desktop' END AS Machine_Type
		--,VUI.Severity
		--,VUI.BulletinID
		--,VUI.ArticleID
		--,VUI.Description
		--,VUI.Title
		--,VUI.DatePosted
FROM
		dbo.v_R_System VS
		LEFT JOIN (
				-- link to the compliance status of each individual update and determine the 
				-- current amount to be deployed as well as the first update required
				-- note: if you hold then release updates, this date is still when they were first available
				-- note: INNER JOIN here and remove WHERE clause if you only want to see outstanding patches
				SELECT	VCS.ResourceID
						,COUNT(*) AS CountOfUpdates
						,MIN(VUI.DatePosted) AS FirstUpdateRequired
				FROM
						dbo.v_UpdateComplianceStatus VCS
						INNER JOIN dbo.v_UpdateInfo VUI ON VCS.CI_ID = VUI.CI_ID 
										AND VCS.Status = 2  -- Required
										AND VUI.IsSuperseded = 0  -- Superseded or not
										AND VUI.Severity > 0
				GROUP BY
						VCS.ResourceID
				) X ON VS.ResourceID = X.ResourceID 
		LEFT JOIN (
			-- link back to see if they have a service window so I can tell whether
			-- updates may be installed
			SELECT
					vsys.Name0 AS [Server Name]
					,MAX(vcol.Name) AS [Collection Name]
			FROM
					dbo.v_FullCollectionMembership fcm 
					INNER JOIN dbo.v_R_System vsys ON fcm.ResourceID = vsys.ResourceID
					INNER JOIN dbo.v_collection vcol ON fcm.CollectionID = vcol.CollectionID
					INNER JOIN dbo.v_ServiceWindow sw ON fcm.CollectionID = sw.CollectionID
			GROUP BY
					vsys.Name0
		) Y ON VS.Name0 = Y.[Server Name]
WHERE
		VS.Active0 = 1
		AND ISNULL(CountOfUpdates,0) > 0 -- only get machines with updatse required
ORDER BY
		VS.Name0 



-- get the details of machines requiring updates to be installed
-- this list could be long if you dont auto patch
SELECT
		VS.Name0 AS [Machine Name]
		-- we have a naming standard, so I can work out the Owner based on the name
		,CASE
			WHEN VS.Name0 LIKE 'XX%' THEN ''
			Else '' 
		END AS [Owner]
		-- here the naming convention helps too
		,CASE
			WHEN VS.Name0 LIKE 'XX%' Then 'Prod' 
			WHEN VS.Name0 LIKE 'YY%' THEN 'Non-Prod'
			ELSE ''
		END AS [Type]
		,VS.Operating_System_Name_and0 as [OS]
		,VS.User_Name0 AS [Primary User]
		,VS.Last_Logon_Timestamp0 AS [LastLogon]
		,Y.[Collection Name]
		,CASE WHEN Operating_System_Name_and0 LIKE '%Server%' THEN 'Server' ELSE 'Desktop' END AS Machine_Type
		,VUI.Severity
		,VUI.BulletinID
		,VUI.ArticleID
		,VUI.Description
		,VUI.Title
		,VUI.DatePosted
FROM
		dbo.v_R_System VS
		INNER JOIN dbo.v_UpdateComplianceStatus VCS ON VS.ResourceID = VCS.ResourceID 
		INNER JOIN dbo.v_UpdateInfo VUI ON VCS.CI_ID = VUI.CI_ID 
		LEFT JOIN (
			-- link back to see if they have a service window so I can tell whether
			-- updates may be installed
			SELECT
					vsys.Name0 AS [Server Name]
					,MAX(vcol.Name) AS [Collection Name]
			FROM
					dbo.v_FullCollectionMembership fcm 
					INNER JOIN dbo.v_R_System vsys ON fcm.ResourceID = vsys.ResourceID
					INNER JOIN dbo.v_collection vcol ON fcm.CollectionID = vcol.CollectionID
					INNER JOIN dbo.v_ServiceWindow sw ON fcm.CollectionID = sw.CollectionID
			GROUP BY
					vsys.Name0
		) Y ON VS.Name0 = Y.[Server Name]
WHERE
		VS.Active0 = 1
		-- filter to the patches required
		AND VCS.Status = 2  -- Required
		AND VUI.IsSuperseded = 0  -- Superseded or not
		AND VUI.Severity > 0
ORDER BY
		VS.Name0 