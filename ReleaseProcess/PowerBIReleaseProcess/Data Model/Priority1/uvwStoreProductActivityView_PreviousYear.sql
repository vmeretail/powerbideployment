CREATE OR ALTER VIEW uvwStoreProductActivityView_PreviousYear
AS

select
StoreProductActivity.EventId,
ActivityDate,
ActivityDateTime, 
calendar.YearWeekNumber,
0 as CurrentStockLevel,
StockTransferQuantity, 
IsDelivery = CASE WHEN storeproductactivity.ActivityType = 1 THEN 1 ELSE 0 END,
DeliveryCount = CASE WHEN storeproductactivity.ActivityType = 1 THEN StockTransferQuantity ELSE 0 END,
IsGap = CASE WHEN storeproductactivity.ActivityType = 2 THEN 1 ELSE 0 END,
GapCount = CASE WHEN storeproductactivity.ActivityType = 2 THEN StockTransferQuantity ELSE 0 END,
IsIBTIn = CASE WHEN storeproductactivity.ActivityType = 3 THEN 1 ELSE 0 END,
IBTInCount = CASE WHEN storeproductactivity.ActivityType = 3 THEN StockTransferQuantity ELSE 0 END,
IsIBTOut = CASE WHEN storeproductactivity.ActivityType = 4 THEN 1 ELSE 0 END,
IBTOutCount = CASE WHEN storeproductactivity.ActivityType = 4 THEN StockTransferQuantity ELSE 0 END,
IsOrder = CASE WHEN storeproductactivity.ActivityType = 5 THEN StockTransferQuantity ELSE 0 END,
-- Currently the Order Count is not captured at the Read Model
--OrderCount = CASE WHEN storeproductactivity.IsOrder = 1 THEN StockTransferQuantity ELSE 0 END,
IsRTC = CASE WHEN storeproductactivity.ActivityType = 6 THEN 1 ELSE 0 END,
RTCCount = CASE WHEN storeproductactivity.ActivityType = 6 THEN 1 ELSE 0 END,
RTCSales = CASE WHEN storeproductactivity.ActivityType = 6 THEN StoreProductActivity.soldforprice  ELSE 0 END,
RetailPrice = storeproductactivity.retailprice,
Variance = storeproductactivity.Variance,
IsSale = CASE WHEN storeproductactivity.ActivityType = 7 THEN 1 ELSE 0 END,
SaleCount = CASE WHEN storeproductactivity.ActivityType = 7 THEN StockTransferQuantity ELSE 0 END,
Sales = CASE 
			WHEN storeproductactivity.ActivityType = 6 THEN soldforprice
			WHEN storeproductactivity.ActivityType = 7 THEN StockTransferQuantity * soldforprice
			ELSE 0 END,
IsStockCheck = CASE WHEN storeproductactivity.ActivityType = 8 THEN 1 ELSE 0 END,
StockCheckCount = CASE WHEN storeproductactivity.ActivityType = 8 THEN StockTransferQuantity ELSE 0 END,
IsStockTake = CASE WHEN storeproductactivity.ActivityType = 9 THEN 1 ELSE 0 END,
StockTakeCount = CASE WHEN storeproductactivity.ActivityType = 9 THEN StockTransferQuantity ELSE 0 END,
IsWastage = CASE WHEN storeproductactivity.ActivityType = 10 THEN 1 ELSE 0 END,
WastageCount = CASE WHEN storeproductactivity.ActivityType = 10 THEN storeproductactivity.StockTransferQuantity ELSE 0 END,
WastageSales = CASE WHEN storeproductactivity.ActivityType = 10 THEN storeproductactivity.StockTransferQuantity * StoreProductActivity.retailprice ELSE 0 END,
0 as IsStockTransfer,
StoreProductActivity.StoreId,
StoreProductActivity.StoreReportingId,
'00000000-0000-0000-0000-000000000000' as [ProductId],
0 as [ProductReportingId],
StoreProductActivity.organisationproductid,
StoreProductActivity.organisationproductreportingid,
CASE 
	WHEN storeproductactivity.ActivityType = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN 'Delivery'
	WHEN storeproductactivity.ActivityType = 2 THEN 'Gap Analysis'
	WHEN storeproductactivity.ActivityType = 3 THEN 'IBT In'
	WHEN storeproductactivity.ActivityType= 4 THEN 'IBT Out'
	WHEN storeproductactivity.ActivityType= 5 THEN 'Ordered'
	WHEN storeproductactivity.ActivityType = 6 THEN 'RTC'
	WHEN storeproductactivity.ActivityType = 7 THEN 'Sale'
	WHEN storeproductactivity.ActivityType = 8 THEN 'Stock Check'
	WHEN storeproductactivity.ActivityType = 9 THEN 'Stock Take'
	WHEN storeproductactivity.ActivityType = 10 THEN 'Wastage'
	ELSE 'Unknown'
END as [ActivityType],
CASE 
	WHEN storeproductactivity.ActivityType = 5 THEN 'Ordered ' + CAST(OrderNumberOfCases  as VARCHAR) + ' Cases'
	WHEN storeproductactivity.ActivityType = 1 OR storeproductactivity.ReasonDescription = 'DELIVERY' THEN 'Delivered ' + CAST(StockTransferQuantity  as VARCHAR) + ' Cases'
	WHEN storeproductactivity.ActivityType IN (6,7) THEN CAST(NumberOfItemsSold  as VARCHAR) + ' Items Sold'
	ELSE 'Unknown'
END as [ActivityTypeExtra],
StoreProductActivity.ReasonDescription,
calendar.[DayOfWeek],
calendar.DayOfWeekNumber,
StoreProductActivity.FutureDate as FutureYearDate,
StoreProductActivity.ActivityType as ActivityTypeInt
from StoreProductActivity_PreviousYear StoreProductActivity
inner join calendar on calendar.Date = StoreProductActivity.ActivityDate