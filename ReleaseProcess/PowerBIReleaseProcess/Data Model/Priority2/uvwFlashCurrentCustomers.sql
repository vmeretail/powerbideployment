CREATE OR ALTER VIEW [dbo].[uvwFlashCurrentCustomers]
AS
SELECT 
	CompletedDate,
	StoreReportingId,
	COUNT(aggregateid) [Customer Count]
FROM salestransactioncompleted
INNER JOIN uvwStoresView ON salestransactioncompleted.StoreId = uvwStoresView.StoreId
GROUP BY
	CompletedDate,
	StoreReportingId

