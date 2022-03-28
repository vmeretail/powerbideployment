CREATE OR ALTER VIEW [dbo].[uvwFlashSalesPrevious]
AS
SELECT
	FutureDate,
	StoreReportingId,
	SoldForPrice [Sales],
	DepartmentId
FROM storeproductactivity_previousyear
WHERE ActivityType IN (6,7)

