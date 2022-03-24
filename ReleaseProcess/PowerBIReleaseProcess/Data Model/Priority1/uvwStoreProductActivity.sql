CREATE OR ALTER VIEW [dbo].[uvwStoreProductActivity]
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
  '00000000-0000-0000-0000-000000000000' as SalesTransactionLineId, 
  storeproductactivity.StockTransferQuantity, 
  storeproductactivity.StoreId, 
  storeproductactivity.StoreProductId, 
  storeproductactivity.StoreProductReportingId, 
  storeproductactivity.SalesTransactionId, 
  storeproductactivity.OrganisationProductId, 
  storeproductactivity.OrganisationProductReportingId, 
  storeproductactivity.RetailPrice,
  ISNULL(storeproductactivity.SoldForPrice, 0) as SoldForPrice,
   CASE storeproductactivity.ActivityType
	WHEN 6 THEN storeproductactivity.RetailPrice - ISNULL(storeproductactivity.SoldForPrice, 0) 
	WHEN 7 THEN storeproductactivity.RetailPrice - ISNULL(storeproductactivity.SoldForPrice, 0) 
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