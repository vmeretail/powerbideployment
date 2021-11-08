CREATE OR ALTER VIEW pocStoreProductActivityView
AS
select
ActivityDate,
ActivityDateTime, 
storeproduct.CurrentStockLevel,
StockTransferQuantity, 
IsDelivery = CASE WHEN storeproductactivity.IsDelivery = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN 1 ELSE 0 END,
DeliveryCount = CASE WHEN storeproductactivity.IsDelivery = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN StockTransferQuantity ELSE 0 END,
IsGap,
GapCount = CASE WHEN storeproductactivity.IsGap = 1 THEN StockTransferQuantity ELSE 0 END,
IsIBTIn,
IBTInCount = CASE WHEN storeproductactivity.IsIBTIn = 1 THEN StockTransferQuantity ELSE 0 END,
IsIBTOut,
IBTOutCount = CASE WHEN storeproductactivity.IsIBTOut = 1 THEN StockTransferQuantity ELSE 0 END,
IsOrder,
-- Currently the Order Count is not captured at the Read Model
--OrderCount = CASE WHEN storeproductactivity.IsOrder = 1 THEN StockTransferQuantity ELSE 0 END,
IsRTC,
RTCCount = CASE WHEN storeproductactivity.IsRTC = 1 THEN (StockTransferQuantity * -1) + NumberOfItemsSold ELSE 0 END,
IsSale = CASE WHEN storeproductactivity.IsSale = 1 THEN 1 ELSE 0 END,
SaleCount = CASE WHEN storeproductactivity.IsSale = 1 THEN (StockTransferQuantity * -1) + NumberOfItemsSold ELSE 0 END,
IsStockCheck,
StockCheckCount = CASE WHEN storeproductactivity.IsStockCheck = 1 THEN StockTransferQuantity ELSE 0 END,
IsStockTake,
StockTakeCount = CASE WHEN storeproductactivity.IsStockTake = 1 THEN StockTransferQuantity ELSE 0 END,
IsWastage,
WastageCount = CASE WHEN storeproductactivity.IsWastage = 1 THEN StockTransferQuantity * -1 ELSE 0 END,
[IsStockTransfer]	= CASE WHEN storeproductactivity.IsGap = 1 OR storeproductactivity.IsIBTIn = 1 OR storeproductactivity.IsIBTOut = 1 OR storeproductactivity.IsStockCheck = 1 OR
													  storeproductactivity.IsWastage = 1 OR storeproductactivity.isStocktransferSale = 1 OR
													  storeproductactivity.ReasonDescription = 'DELIVERY' THEN 1 ELSE 0 END,
store.StoreId,
store.StoreReportingId,
storeproduct.StoreProductId as [ProductId],
storeproduct.StoreProductReportingId as [ProductReportingId],
organisationproduct.organisationproductid,
organisationproduct.organisationproductreportingid,
CASE 
	WHEN IsDelivery = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN 'Delivery'
	WHEN IsGap = 1 THEN 'Gap Analysis'
	WHEN IsIBTIn = 1 THEN 'IBT In'
	WHEN IsIBTOut = 1 THEN 'IBT Out'
	WHEN IsOrder = 1 THEN 'Ordered'
	WHEN IsRTC = 1 THEN 'RTC'
	WHEN IsSale = 1 THEN 'Sale'
	WHEN IsStockCheck = 1 THEN 'Stock Check'
	WHEN IsWastage = 1 THEN 'Wastage'
	ELSE 'Unknown'
END as [ActivityType],
CASE 
	WHEN IsOrder = 1 THEN 'Ordered ' + CAST(OrderNumberOfCases  as VARCHAR) + ' Cases'
	WHEN IsDelivery = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN 'Delivered ' + CAST(StockTransferQuantity  as VARCHAR) + ' Cases'
	WHEN IsSale = 1 THEN CAST(NumberOfItemsSold  as VARCHAR) + ' Items Sold'	
	ELSE 'Unknown'
END as [ActivityTypeExtra],
ReasonDescription
from storeproductactivity 
inner join StoreProductStateProjection storeproduct on storeproduct.StoreProductReportingId = storeproductactivity.StoreProductReportingId
inner join StoreProjectionState store on store.StoreReportingId = storeproduct.StoreReportingId
inner join OrganisationProductProjectionState organisationproduct on organisationproduct.OrganisationProductReportingId = storeproduct.OrganisationProductReportingId
where (CAST(IsDelivery as INT) + CAST(IsGap as INT) + CAST(IsIBTIn as INT)+ CAST(IsIBTOut as INT)+ CAST(IsOrder as INT)+ CAST(IsRTC as INT)+ CAST(IsSale as INT)+ CAST(IsWastage as INT)) > 0