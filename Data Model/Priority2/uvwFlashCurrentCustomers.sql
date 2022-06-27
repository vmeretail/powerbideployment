IF OBJECT_ID('dbo.[uvwFlashCurrentCustomers]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwFlashCurrentCustomers]; 
GO; 

CREATE VIEW [dbo].[uvwFlashCurrentCustomers]
AS
SELECT 
	CompletedDate,
	salestransactioncompleted.StoreReportingId,
	COUNT(aggregateid) [Customer Count]
FROM salestransactioncompleted
inner join salestransactionline on salestransactionline.aggregateid = salestransactioncompleted.aggregateid
inner join uvwHierarchyDepartmentView on uvwHierarchyDepartmentView.departmentid = salestransactionline.departmentid
WHERE salestransactioncompleted.BasketTotal != 0
	  and salestransactioncompleted.AmountToPayWasVoided = 0
GROUP BY
	CompletedDate,
	salestransactioncompleted.StoreReportingId

