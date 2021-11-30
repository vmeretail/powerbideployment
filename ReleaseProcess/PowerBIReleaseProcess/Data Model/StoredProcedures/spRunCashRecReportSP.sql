CREATE OR ALTER PROCEDURE [dbo].[spRunCashRecReportSP] @reportStartDate DATETIME
AS

DECLARE @DepartmentId UNIQUEIDENTIFIER  
DECLARE db_cursor CURSOR FOR 
	SELECT DISTINCT [DepartmentId]
	FROM [dbo].[producthierarchy]

BEGIN TRY
	DROP TABLE ##salesInReportDate
END TRY
BEGIN CATCH
  --IGNORE EXCEPTION IF TABLE DOES NOT EXIST
END CATCH
	
SELECT salestransactionline.aggregateId, salestransactionline.departmentId
INTO ##salesInReportDate
FROM salestransactionline
INNER JOIN salestransactioncompleted ON salestransactioncompleted.AggregateId = salestransactionline.aggregateId
WHERE salestransactioncompleted.CompletedDate >= @reportStartDate

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DepartmentId  

WHILE @@FETCH_STATUS = 0  
BEGIN 
	EXEC [dbo].[spBuildDepartmentCashRecReport] @reportStartDate, @DepartmentId
    
	FETCH NEXT FROM db_cursor INTO @DepartmentId	  
END 

CLOSE db_cursor
DEALLOCATE db_cursor