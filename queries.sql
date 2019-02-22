---Probe Summary by Day
SELECT [Date]
     , [1] AS Yes
     , [0] AS No
  FROM (
	SELECT cast(test_datetime as date) AS [Date]
         , test_failed
         , count(*) AS [Volume]
      FROM [master].dba.probe_sqlserver_connectivity
     GROUP BY cast(test_datetime as date), test_failed
) p PIVOT ( SUM ([Volume]) FOR test_failed IN ([0], [1]) ) AS pvt  
ORDER BY pvt.[Date] DESC;  

---Probe Summary by Hour
SELECT [Hour]
     , [1] AS Yes
     , [0] AS No
  FROM (
	SELECT DATEPART(hour, test_datetime) AS [Hour]
         , test_failed
         , count(*) AS [Volume]
      FROM [master].dba.probe_sqlserver_connectivity
	 WHERE CAST(GETDATE() AS date) = cast(test_datetime as date)
     GROUP BY DATEPART(hour, test_datetime), test_failed
) p PIVOT ( SUM ([Volume]) FOR test_failed IN ([0], [1]) ) AS pvt  
ORDER BY pvt.[Hour] DESC;  

---Probe Detail
SELECT *
  FROM [master].dba.probe_sqlserver_connectivity
--WHERE test_datetime BETWEEN '' AND ''
 ORDER BY test_datetime DESC;