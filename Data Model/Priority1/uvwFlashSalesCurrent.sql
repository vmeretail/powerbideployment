CREATE OR ALTER VIEW [dbo].[uvwFlashSalesCurrent]
AS
SELECT 
	StoreProductActivity.ActivityDate,
	StoreProductActivity.StoreReportingId,
	StoreProductActivity.SalesTransactionId,
	StoreProductActivity.DepartmentId,
	StoreProductActivity.SoldForPrice as Sales
FROM StoreProductActivity
WHERE ActivityType IN (6,7)

