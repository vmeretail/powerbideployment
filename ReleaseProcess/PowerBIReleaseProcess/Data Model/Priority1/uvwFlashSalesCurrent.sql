CREATE OR ALTER VIEW [dbo].[uvwFlashSalesCurrent]
AS
SELECT
	ActivityDate,
	StoreReportingId,
	SalesTransactionId,
	DepartmentId,
	ISNULL(SoldForPrice, 0) Sales
FROM storeproductactivity 
WHERE ActivityType IN (6,7)

