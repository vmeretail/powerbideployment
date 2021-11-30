CREATE OR ALTER   PROCEDURE [dbo].[spBuildDepartmentCashRecReport] @reportStartDate datetime, @DepartmentId uniqueidentifier
AS
	delete from CashRecReporting WHERE ReportDate >= @reportStartDate and DepartmentId = @DepartmentId

	insert into CashRecReporting(
		ReportDate, 
		StoreId,
		DepartmentId, 
		basketCount,
		basketTotal,
		saleType,
		marginTotal)

	-- total sales
	select salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, @DepartmentId, count(distinct salestransactioncompleted.aggregateId), sum(salestransactioncompleted.baskettotal), 'total', sum(salestransactioncompleted.MarginValue)
	from 
	(	
		select distinct aggregateId
		from ##salesInReportDate
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId

	union all 

	-- sales with only the interesting department
	select salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, @DepartmentId, count(*), sum(salestransactioncompleted.baskettotal), 'onlyselecteddepartment', sum(salestransactioncompleted.MarginValue)
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		where salestransactionline.aggregateId IN (select distinct ##salesInReportDate.aggregateId
		from ##salesInReportDate
		where departmentId = @departmentid)	
		group by salestransactionline.aggregateId
		having count(distinct salestransactionline.departmentId) = 1
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId		

	union all

	-- sales with the interesting department but others
	select salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, @DepartmentId, count(*), sum(salestransactioncompleted.baskettotal), 'includingselecteddepartment', sum(salestransactioncompleted.MarginValue)
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		where salestransactionline.aggregateId IN (select distinct ##salesInReportDate.aggregateId
		from ##salesInReportDate
		where departmentId = @departmentid)	
		group by salestransactionline.aggregateId
		having count(distinct salestransactionline.departmentId) > 1
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId
	
	union all

	select salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId, @DepartmentId, count(*), sum(salestransactioncompleted.baskettotal), 'excludingselecteddepartment', sum(salestransactioncompleted.MarginValue)
	from 
	(
		select distinct salestransactionline.aggregateId 
		from salestransactionline
		inner join ##salesInReportDate on ##salesInReportDate.aggregateId = salestransactionline.aggregateId
		where salestransactionline.aggregateId NOT IN (select distinct ##salesInReportDate.aggregateId
		from ##salesInReportDate
		where departmentId = @departmentid)
	) as result
	inner join salestransactioncompleted on salestransactioncompleted.AggregateId = result.AggregateId
	group by salestransactioncompleted.CompletedDate, salestransactioncompleted.StoreId