CREATE OR ALTER VIEW [dbo].[uvwFlashSalesCurrent]
AS
SELECT
	ActivityDate,
	StoreReportingId,
	SalesTransactionId,
	DepartmentId,
	CASE WHEN storeproductactivity.NumberOfItemsSold < 0
		THEN ISNULL(storeproductactivity.SoldForPrice, 0) * -1
		ELSE ISNULL(storeproductactivity.SoldForPrice, 0) 
	END Sales
FROM storeproductactivity 
WHERE ActivityType IN (6,7)

