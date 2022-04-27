CREATE OR ALTER VIEW [dbo].[uvwFlashSalesCurrent]
AS
SELECT 
	StoreProductActivity.ActivityDate,
	StoreProductActivity.StoreReportingId,
	StoreProductActivity.SalesTransactionId,
	StoreProductActivity.DepartmentId,
	salestransactionline.LineTotalAfterDeductions as Sales
FROM StoreProductActivity
inner join salestransactionline on salestransactionline.AggregateId = storeproductactivity.SalesTransactionId and salestransactionline.EventId = storeproductactivity.EventId 
WHERE ActivityType IN (6,7)

