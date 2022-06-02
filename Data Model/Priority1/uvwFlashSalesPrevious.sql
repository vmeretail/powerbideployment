IF OBJECT_ID('dbo.[uvwFlashSalesPrevious]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwFlashSalesPrevious]; 
GO; 

CREATE VIEW [dbo].[uvwFlashSalesPrevious]
AS
SELECT
	FutureDate,
	StoreReportingId,
	SoldForPrice [Sales],
	DepartmentId
FROM storeproductactivity_previousyear
WHERE ActivityType IN (6,7)

