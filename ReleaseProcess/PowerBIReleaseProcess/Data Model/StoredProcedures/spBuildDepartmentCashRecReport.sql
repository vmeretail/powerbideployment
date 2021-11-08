CREATE OR ALTER   PROCEDURE [dbo].[spBuildDepartmentCashRecReport] @reportStartDate datetime, @DepartmentId uniqueidentifier
AS
	select salestransactionline.aggregateId, salestransactionline.departmentId
	into #salesInReportDate
	from salestransactionline
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = salestransactionline.aggregateId
	where salestransactioncompleted.CompletedDate >= @reportStartDate

	delete from CashRecReporting WHERE ReportDate >= @reportStartDate

	select 'Total Sales'  as description, salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, count(distinct salestransactioncompleted.aggregateId) as basketCount, sum(salestransactioncompleted.baskettotal) as basketTotal,
	sum(salestransactioncompleted.MarginValue) as marginTotal
	into #totalsales
	from 
	(	
		select distinct aggregateId
		from #salesInReportDate
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId

	-- sales with only the interesting department
	select 'Sales with only department' as description, salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, count(*) as basketCount, sum(salestransactioncompleted.baskettotal) as basketTotal,
	sum(salestransactioncompleted.MarginValue) as marginTotal
	into #saleswithonlyselecteddepartment
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		where salestransactionline.aggregateId IN (select distinct #salesInReportDate.aggregateId
		from #salesInReportDate
		where departmentId = @departmentid)	
		group by salestransactionline.aggregateId
		having count(distinct salestransactionline.departmentId) = 1
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId		

	-- sales with the interesting department but others
	select 'Sales with department and other stuff' as description,salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, count(*) as basketCount, sum(salestransactioncompleted.baskettotal) as basketTotal, 
	sum(salestransactioncompleted.MarginValue) as marginTotal
	into #saleswithselecteddepartmentandothers
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		where salestransactionline.aggregateId IN (select distinct #salesInReportDate.aggregateId
		from #salesInReportDate
		where departmentId = @departmentid)	
		group by salestransactionline.aggregateId
		having count(distinct salestransactionline.departmentId) > 1
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId

	select 'Sales with nothing from department' as description, salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId,count(*) as basketCount, sum(salestransactioncompleted.baskettotal) as basketTotal,
	sum(salestransactioncompleted.MarginValue) as marginTotal
	into #saleswithoutselecteddepartment
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		inner join #salesInReportDate on #salesInReportDate.aggregateId = salestransactionline.aggregateId
		where salestransactionline.aggregateId NOT IN (select distinct #salesInReportDate.aggregateId
		from #salesInReportDate
		where departmentId = @departmentid)
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId	

	insert into CashRecReporting(
		ReportDate, 
		DepartmentId, 
		StoreId,

		basketCount,
		basketTotal,
		saleType,
		marginTotal)

	select 		

		#totalsales.CompletedDate as ReportDate,  
		@DepartmentId as DepartmentId, 
		#totalsales.StoreId,
		#totalsales.basketCount,
		#totalsales.basketTotal,
		'total' as saleType,
		#totalsales.marginTotal
	from #totalsales

	insert into CashRecReporting(
		ReportDate, 
		Departmentid, 
		StoreId, 

		basketCount,
		basketTotal,
		saleType,
		marginTotal
	)
	select 		

		#saleswithonlyselecteddepartment.CompletedDate as ReportDate,   
		@DepartmentId as DepartmentId, 
		#saleswithonlyselecteddepartment.StoreId,
		#saleswithonlyselecteddepartment.basketCount,
		#saleswithonlyselecteddepartment.basketTotal,
		'onlyselecteddepartment',
		#saleswithonlyselecteddepartment.marginTotal
	from #saleswithonlyselecteddepartment

	insert into CashRecReporting(
		ReportDate, 
		Departmentid, 
		StoreId, 

		basketCount,
		basketTotal,
		saleType,
		marginTotal
	)
	select 		

		#saleswithselecteddepartmentandothers.CompletedDate as ReportDate,  
		@DepartmentId as DepartmentId, 
		#saleswithselecteddepartmentandothers.StoreId,
		#saleswithselecteddepartmentandothers.basketCount,
		#saleswithselecteddepartmentandothers.basketTotal,
		'includingselecteddepartment',
		#saleswithselecteddepartmentandothers.marginTotal
	from #saleswithselecteddepartmentandothers


	insert into CashRecReporting(
		ReportDate, 
		Departmentid, 
		StoreId, 

		basketCount,
		basketTotal,
		saleType,
		marginTotal
	)
	select 		

		#saleswithoutselecteddepartment.CompletedDate as ReportDate,   
		@DepartmentId as DepartmentId, 
		#saleswithoutselecteddepartment.StoreId,
		#saleswithoutselecteddepartment.basketCount,
		#saleswithoutselecteddepartment.basketTotal,
		'excludingselecteddepartment',
		#saleswithoutselecteddepartment.marginTotal
	from #saleswithoutselecteddepartment