IF OBJECT_ID('dbo.[uvwStoreProductActivity_PreviousYear]', 'V') IS NOT NULL 
  DROP VIEW dbo.[uvwStoreProductActivity_PreviousYear]; 
GO; 

CREATE VIEW [dbo].[uvwStoreProductActivity_PreviousYear]
AS
SELECT        
  storeproductactivity.EventId, 
  storeproductactivity.FutureDate as ActivityDate, 
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
  storeproductactivity.ReasonDescription, 
  storeproductactivity.SalesTransactionLineId, 
  storeproductactivity.StockTransferQuantity, 
  storeproductactivity.StoreId, 
  storeproductactivity.StoreProductId, 
  storeproductactivity.StoreProductReportingId, 
  storeproductactivity.SalesTransactionId, 
  storeproductactivity.OrganisationProductId, 
  storeproductactivity.OrganisationProductReportingId, 
  storeproductactivity.SoldForPrice,
  storeproductactivity.RetailPrice,
  storeproductactivity.Variance,
  storeproductactivity.StoreReportingId,
  storeproductactivity.ActivityType,
  storeproductactivity.SubsectionId,
  storeproductactivity.SectionId,
  storeproductactivity.DepartmentId
FROM StoreProductActivity_PreviousYear as storeproductactivity
