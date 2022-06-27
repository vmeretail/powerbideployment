IF OBJECT_ID('dbo.[spBuildDepartmentCashRecReport]', 'P') IS NOT NULL 
  DROP PROCEDURE dbo.[spBuildDepartmentCashRecReport]; 
GO; 

CREATE PROCEDURE [dbo].[spBuildDepartmentCashRecReport] @reportStartDate datetime
AS
	DELETE FROM CashRecReporting WHERE ReportDate = @reportStartDate

		-- total sales
	SELECT DISTINCT departmentId INTO #department from producthierarchy WITH(nolock)

	INSERT INTO CashRecReporting
	(
		ReportDate, 
		DepartmentId, 
		StoreId,
		basketCount,
		basketTotal,
		saleType,
		marginTotal
	)
	select 	salestransactioncompleted.CompletedDate,
			#department.DepartmentId,
			salestransactioncompleted.StoreId, 
			COUNT(DISTINCT salestransactioncompleted.aggregateId), 
			SUM(salestransactioncompleted.baskettotal), 
			'total', 
			SUM(salestransactioncompleted.MarginValue) 
	from salestransactioncompleted WITH(nolock)
	CROSS JOIN #department
	WHERE salestransactioncompleted.CompletedDate = @reportStartDate
	group by CompletedDate, storeid,#department.DepartmentId

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
	FROM salestransactioncompleted WITH(nolock)
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
	WHERE salestransactioncompleted.CompletedDate = @reportStartDate AND departmentId IS NOT NULL
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
	FROM salestransactioncompleted WITH(nolock)
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
	WHERE salestransactioncompleted.CompletedDate = @reportStartDate AND departmentId IS NOT NULL
	GROUP BY salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, departmentId

	DECLARE @DepartmentId UNIQUEIDENTIFIER  
	DECLARE db_cursor CURSOR FOR 
		SELECT DISTINCT [DepartmentId]
		FROM [dbo].[producthierarchy]
	
	SELECT salestransactionline.aggregateId, salestransactionline.departmentId
	INTO #salesInReportDate
	FROM salestransactionline WITH(nolock)
	INNER JOIN salestransactioncompleted WITH(nolock) ON salestransactioncompleted.AggregateId = salestransactionline.aggregateId
	WHERE salestransactioncompleted.CompletedDate = @reportStartDate

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @DepartmentId  

	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		INSERT INTO CashRecReporting
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
			FROM salestransactionline WITH(nolock)
			INNER JOIN #salesInReportDate on #salesInReportDate.aggregateId = salestransactionline.aggregateId
			WHERE salestransactionline.aggregateId NOT IN (SELECT DISTINCT #salesInReportDate.aggregateId
			FROM #salesInReportDate
			WHERE departmentId = @DepartmentId)
		) AS result
		INNER JOIN salestransactioncompleted WITH(nolock) ON salestransactioncompleted.AggregateId = result.AggregateId
		group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId	
    
		declare @includingcount int
		declare @onlycount int

		select @includingcount = count(*) from cashrecreporting where  DepartmentId = @DepartmentId and SaleType = 'includingselecteddepartment' and ReportDate = @reportStartDate

		if (@includingcount = 0)
		BEGIN
			-- Insert zero rows
			INSERT INTO cashrecreporting(
			ReportDate, 
			DepartmentId, 
			StoreId,
			basketCount,
			basketTotal,
			saleType,
			marginTotal)
			SELECT ReportDate, 
			DepartmentId, 
			StoreId,
			0,
			0,
			'includingselecteddepartment',
			0 
			from cashrecreporting where  DepartmentId = @DepartmentId  and ReportDate = @reportStartDate and SaleType = 'total'
		END
		
		select @onlycount = count(*) from cashrecreporting where  DepartmentId = @DepartmentId and SaleType = 'onlyselecteddepartment' and DepartmentId = 'A11A43AA-28CB-502E-7757-7F2E7459CF3D'

		if (@onlycount = 0)
		BEGIN
			-- Insert zero rows
			INSERT INTO cashrecreporting(
			ReportDate, 
			DepartmentId, 
			StoreId,
			basketCount,
			basketTotal,
			saleType,
			marginTotal)
			SELECT ReportDate, 
			DepartmentId, 
			StoreId,
			0,
			0,
			'onlyselecteddepartment',
			0 
			from cashrecreporting where  DepartmentId = @DepartmentId  and ReportDate = @reportStartDate and SaleType = 'total'
		END

		FETCH NEXT FROM db_cursor INTO @DepartmentId	  
	END 

	CLOSE db_cursor
	DEALLOCATE db_cursor