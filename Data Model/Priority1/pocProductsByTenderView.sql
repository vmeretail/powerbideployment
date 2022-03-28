CREATE OR ALTER VIEW [dbo].[pocProductsByTenderView]
AS
SELECT 
	salestransactioncompleted.AggregateId, 
	paymenttype, 
	productDescription, 
	Quantity, 
	LineTotalInc, 
	CompletedDate, 
	store.[Name] Store, 
	DepartmentName	
FROM salestransactioncompleted
INNER JOIN salestransactionline on salestransactionline.aggregateid = salestransactioncompleted.AggregateId
INNER JOIN store ON store.StoreId = salestransactioncompleted.StoreId
INNER JOIN producthierarchy ON producthierarchy.ProductHierarchyId = salestransactionline.departmentId