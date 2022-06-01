IF OBJECT_ID('dbo.[uvwFlashCurrentCustomers]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwFlashCurrentCustomers]; 
GO; 

CREATE VIEW [dbo].[uvwFlashCurrentCustomers]
AS
SELECT 
	CompletedDate,
	uvwStoresView.StoreReportingId,
	COUNT(aggregateid) [Customer Count]
FROM salestransactioncompleted
INNER JOIN uvwStoresView ON salestransactioncompleted.StoreId = uvwStoresView.StoreId
WHERE salestransactioncompleted.BasketTotal != 0
GROUP BY
	CompletedDate,
	uvwStoresView.StoreReportingId

