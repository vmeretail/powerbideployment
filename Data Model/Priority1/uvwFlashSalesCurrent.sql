IF OBJECT_ID('dbo.[uvwFlashSalesCurrent]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwFlashSalesCurrent]; 
GO; 

CREATE VIEW [dbo].[uvwFlashSalesCurrent]
AS
SELECT 
	StoreProductActivity.ActivityDate,
	StoreProductActivity.StoreReportingId,
	StoreProductActivity.SalesTransactionId,
	StoreProductActivity.DepartmentId,
	StoreProductActivity.SoldForPrice as Sales
FROM StoreProductActivity
WHERE ActivityType IN (6,7)

