SET NOCOUNT ON

-- determine where machines registered in SCCM are currently requiring a reboot
SELECT
		DCM.MName
		,DCM.Baseline
		,DCM.[Reboot Required]
		,DCM.StartTime
		-- attempt to linkt to a service window to see if they will auto-reboot (I use this for reporting)
		,SW.[Server Name]
		,SW.[Collection Name]
		,SW.[Description]
		,SW.[Duration (Min)]
FROM
		(
			SELECT DISTINCT 
					NonCompliantAssets.AssetName AS 'MName'
					,NonCompliantAssets.BLName AS 'Baseline' 
					,'Yes' AS 'Reboot Required' 
					,StartTime
			FROM
					fn_DCMDeploymentNonCompliantAssetDetails(1033) NonCompliantAssets
			UNION
			SELECT
					UnknownAssets.MachineName AS 'MName'
					,UnknownAssets.SoftwareName AS 'Baseline'
					,'Unknown' AS 'Reboot Required' 
					,StartTime
			FROM
					fn_CIDeploymentUnknownAssetDetails(1033) UnknownAssets 
			) DCM 
			LEFT JOIN (
				SELECT
						vsys.Name0 AS [Server Name]
						,vcol.Name AS [Collection Name]
						,sw.Description
						,sw.Duration AS [Duration (Min)]
				FROM
						dbo.v_ServiceWindow sw
						INNER JOIN dbo.v_FullCollectionMembership fcm ON sw.CollectionID = fcm.CollectionID
						FULL OUTER JOIN dbo.v_R_System vsys ON fcm.ResourceID = vsys.ResourceID
						FULL OUTER JOIN dbo.v_collection vcol ON fcm.CollectionID = vcol.CollectionID
			) SW ON DCM.MName = SW.[Server Name]
WHERE
		DCM.[Reboot Required] = 'Yes'
		--AND DCM.MName IN ('') -- add some custom machine names here to filter down to a specifc list
ORDER BY 
		DCM.MName
