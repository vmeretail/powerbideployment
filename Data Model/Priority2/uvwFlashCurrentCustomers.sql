CREATE OR ALTER VIEW [dbo].[uvwFlashCurrentCustomers]
AS
SELECT 
	CompletedDate,
	StoreReportingId,
	COUNT(aggregateid) [Customer Count]
FROM salestransactioncompleted
INNER JOIN uvwStoresView ON salestransactioncompleted.StoreId = uvwStoresView.StoreId
WHERE salestransactioncompleted.BasketTotal != 0
GROUP BY
	CompletedDate,
	StoreReportingId

