CREATE OR ALTER   PROCEDURE [dbo].[spBuildDepartmentCashRecReport] @reportStartDate datetime, @DepartmentId uniqueidentifier
AS
	DELETE FROM CashRecReportingTEST WHERE ReportDate >= @reportStartDate

	INSERT INTO CashRecReportingTEST
	(
		ReportDate, 
		DepartmentId, 
		StoreId,
		basketCount,
		basketTotal,
		saleType,
		marginTotal
	)

	-- total sales
	SELECT 
		salestransactioncompleted.CompletedDate, 
		departmentId, 
		salestransactioncompleted.StoreId, 
		COUNT(DISTINCT salestransactioncompleted.aggregateId), 
		SUM(salestransactioncompleted.baskettotal), 
		'total', 
		SUM(salestransactioncompleted.MarginValue)
	FROM 
	(
		SELECT DISTINCT departmentId from producthierarchy
	) department
	INNER JOIN salestransactioncompleted On 1 = 1
	WHERE salestransactioncompleted.CompletedDate >= @reportStartDate
	GROUP BY salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, departmentId

	UNION ALL

	-- sales with only the interesting department
	SELECT 
		salestransactioncompleted.CompletedDate, 
		departmentId, 
		salestransactioncompleted.StoreId, 
		count(*), 
		SUM(salestransactioncompleted.baskettotal), 
		'onlyselecteddepartment', 
		SUM(salestransactioncompleted.MarginValue)
	FROM salestransactioncompleted
	INNER JOIN
	(
		SELECT DISTINCT a.aggregateId, departmentId 
		FROM 
		(
			SELECT aggregateId 
			FROM salestransactionline
			GROUP BY aggregateId
			HAVING COUNT(DISTINCT departmentId) = 1
		) a
		INNER JOIN  
		(
			SELECT aggregateId, departmentId
			FROM salestransactionline
		) b ON a.AggregateId = b.AggregateId
	) result ON salestransactioncompleted.AggregateId = result.AggregateId
	WHERE salestransactioncompleted.CompletedDate >= @reportStartDate AND departmentId IS NOT NULL
	GROUP BY salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, departmentId

	UNION ALL

	-- sales with the interesting department but others
	SELECT 
		salestransactioncompleted.CompletedDate, 
		departmentId, 
		salestransactioncompleted.StoreId, 
		count(*), 
		SUM(salestransactioncompleted.baskettotal), 
		'includingselecteddepartment', 
		SUM(salestransactioncompleted.MarginValue)
	FROM salestransactioncompleted
	INNER JOIN
	(
		SELECT DISTINCT a.aggregateId, departmentId 
		FROM 
		(
			SELECT aggregateId 
			FROM salestransactionline
			GROUP BY aggregateId
			HAVING COUNT(DISTINCT departmentId) > 1
		) a
		INNER JOIN  
		(
			SELECT aggregateId, departmentId
			FROM salestransactionline
		) b ON a.AggregateId = b.AggregateId
	) result ON salestransactioncompleted.AggregateId = result.AggregateId
	WHERE salestransactioncompleted.CompletedDate >= @reportStartDate AND departmentId IS NOT NULL
	GROUP BY salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, departmentId

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
		INSERT INTO CashRecReportingTEST
		(
			ReportDate, 
			DepartmentId, 
			StoreId,
			basketCount,
			basketTotal,
			saleType,
			marginTotal
		)

		SELECT 
			salestransactioncompleted.CompletedDate, 
			@DepartmentId, 
			salestransactioncompleted.StoreId, 
			COUNT(*), 
			SUM(salestransactioncompleted.baskettotal), 
			'excludingselecteddepartment', 
			SUM(salestransactioncompleted.MarginValue)
		FROM 
		(
			SELECT DISTINCT salestransactionline.aggregateId 
			FROM salestransactionline
			INNER JOIN ##salesInReportDate on ##salesInReportDate.aggregateId = salestransactionline.aggregateId
			WHERE salestransactionline.aggregateId NOT IN (SELECT DISTINCT ##salesInReportDate.aggregateId
			FROM ##salesInReportDate
			WHERE departmentId = @DepartmentId)
		) AS result
		INNER JOIN salestransactioncompleted ON salestransactioncompleted.AggregateId = result.AggregateId
		group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId	
    
		FETCH NEXT FROM db_cursor INTO @DepartmentId	  
	END 

	CLOSE db_cursor
	DEALLOCATE db_cursor