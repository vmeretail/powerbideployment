IF OBJECT_ID('dbo.[uvwStoreProductActivity]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwStoreProductActivity]; 
GO; 

CREATE VIEW [dbo].[uvwStoreProductActivity]
AS
SELECT        
  storeproductactivity.EventId, 
  storeproductactivity.ActivityDate, 
  storeproductactivity.ActivityDateTime, 
  storeproductactivity.CurrentStockLevel,
  storeproductactivity.IsDelivery, 
  storeproductactivity.IsGap, 
  storeproductactivity.IsIBTIn, 
  storeproductactivity.IsIBTOut, 
  storeproductactivity.IsOrder, 
  storeproductactivity.IsRTC, 
  storeproductactivity.IsSale, 
  storeproductactivity.IsStockCheck, 
  storeproductactivity.IsStockTake, 
  storeproductactivity.IsStockTransfer, 
  storeproductactivity.IsStockTransferSale, 
  storeproductactivity.IsWastage, 
  storeproductactivity.NumberOfItemsSold, 
  storeproductactivity.OrderCaseSize, 
  storeproductactivity.OrderNumberOfCases, 
  CASE ActivityType 
	WHEN 6 THEN 'RTC'
	WHEN 7 THEN 'Sale'
	ELSE storeproductactivity.ReasonDescription END as ReasonDescription,
  '00000000-0000-0000-000000000000' as SalesTransactionLineId, 
  storeproductactivity.StockTransferQuantity, 
  storeproductactivity.StoreId, 
  storeproductactivity.StoreProductId, 
  storeproductactivity.StoreProductReportingId, 
  storeproductactivity.SalesTransactionId, 
  storeproductactivity.OrganisationProductId, 
  storeproductactivity.OrganisationProductReportingId,
  CASE WHEN storeproductactivity.NumberOfItemsSold < 0
	THEN ISNULL(storeproductactivity.RetailPrice, 0) * -1
	ELSE ISNULL(storeproductactivity.RetailPrice, 0) END as RetailPrice,
   storeproductactivity.SoldForPrice as SoldForPrice,
   CASE storeproductactivity.ActivityType
	WHEN 6 THEN CASE WHEN NumberOfitemsSold < 0 THEN storeproductactivity.OriginalPrice * -1 ELSE storeproductactivity.OriginalPrice END 	
	ELSE 0 
	END as Variance,
  storeproductactivity.StoreReportingId,
  storeproductactivity.ActivityType,
  storeproductactivity.SubSectionId as SubsectionId,
  storeproductactivity.SectionId as SectionId,
  storeproductactivity.DepartmentId,
  OrganisationProductProjectionState.Description as ProductDescription,
  OrganisationProductProjectionState.ExternalProductId
FROM StoreProductActivity as storeproductactivity
inner join OrganisationProductProjectionState on OrganisationProductProjectionState.OrganisationProductReportingId = storeproductactivity.OrganisationProductReportingId
inner join uvwHierarchyDepartmentView on uvwHierarchyDepartmentView.DepartmentId = storeproductactivity.DepartmentId