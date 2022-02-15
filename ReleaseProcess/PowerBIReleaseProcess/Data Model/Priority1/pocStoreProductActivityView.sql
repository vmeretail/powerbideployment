CREATE OR ALTER VIEW pocStoreProductActivityView
AS
select top 1
ActivityDate,
ActivityDateTime, 
calendar.YearWeekNumber,
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
RTCSalesRetailPrice = CASE WHEN storeproductactivity.IsRTC = 1 THEN salestransactionline.StandardRetailPriceInc * salestransactionline.Quantity ELSE 0 END,
RTCSales = CASE WHEN storeproductactivity.IsRTC = 1 THEN salestransactionline.LineTotalInc ELSE 0 END,
RTCVariance = CASE WHEN storeproductactivity.IsRTC = 1 THEN (salestransactionline.StandardRetailPriceInc * salestransactionline.Quantity) - salestransactionline.LineTotalInc ELSE 0 END,
IsSale = CASE WHEN storeproductactivity.IsSale = 1 THEN 1 ELSE 0 END,
SaleCount = CASE WHEN storeproductactivity.IsSale = 1 THEN (StockTransferQuantity * -1) + NumberOfItemsSold ELSE 0 END,
Sales = CASE WHEN storeproductactivity.IsSale = 1 THEN ((StockTransferQuantity * -1) + NumberOfItemsSold) * priceState.Price ELSE 0 END,
IsStockCheck,
StockCheckCount = CASE WHEN storeproductactivity.IsStockCheck = 1 THEN StockTransferQuantity ELSE 0 END,
IsStockTake,
StockTakeCount = CASE WHEN storeproductactivity.IsStockTake = 1 THEN StockTransferQuantity ELSE 0 END,
IsWastage,
WastageCount = CASE WHEN storeproductactivity.IsWastage = 1 THEN StockTransferQuantity * -1 ELSE 0 END,
WastageSales = CASE WHEN storeproductactivity.IsWastage = 1 THEN (StockTransferQuantity * priceState.Price) * -1 ELSE 0 END,
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
storeproductactivity.ReasonDescription
from storeproductactivity 
inner join calendar on calendar.Date = StoreProductActivity.ActivityDate
inner join StoreProductStateProjection storeproduct on storeproduct.StoreProductReportingId = storeproductactivity.StoreProductReportingId
inner join StoreProjectionState store on store.StoreReportingId = storeproduct.StoreReportingId
inner join OrganisationProductProjectionState organisationproduct on organisationproduct.OrganisationProductReportingId = storeproduct.OrganisationProductReportingId
inner join OrganisationProductPriceProjectionState priceState on priceState.OrganisationProductReportingId = organisationproduct.OrganisationProductReportingId and priceState.Band = store.PriceBand
left outer join salestransactionline on salestransactionline.EventId = StoreProductActivity.EventId
where (CAST(IsDelivery as INT) + CAST(IsGap as INT) + CAST(IsIBTIn as INT)+ CAST(IsIBTOut as INT)+ CAST(IsOrder as INT)+ CAST(IsRTC as INT)+ CAST(IsSale as INT)+ CAST(IsWastage as INT)) > 0

union all

-- previous year wastage data
select
StockTransferSummary.CompletedDate as ActivityDate,
StockTransferSummary.CompletedDate as ActivityDateTime, 
calendar.YearWeekNumber,
storeproduct.CurrentStockLevel,
StockTransferSummary.Items as StockTransferQuantity,
0 as IsDelivery,
0 as DeliveryCount,
0 as IsGap,
0 as GapCount,
0 as IsIBTIn,
0 as IBTInCount,
0 as IsIBTOut,
0 as IBTOutCount,
0 as IsOrder,
0 as IsRTC,
0 as RTCCount,
0 as RTCSalesRetailPrice,
0 as RTCSales,
0 as RTCVariance,
0 as IsSale,
0 as SaleCount,
0 as Sales,
0 as IsStockCheck,
0 as StockCheckCount,
0 as IsStockTake,
0 as StockTakeCount,
1  as IsWastage,
Items as WastageCount,
StockTransferSummary.SaleLineExc as WastageSales,
1 as [IsStockTransfer],
store.StoreId,
StoreProjectionState.StoreReportingId,
storeproduct.StoreProductId as [ProductId],
storeproduct.StoreProductReportingId as [ProductReportingId],
OrganisationProductProjectionState.organisationproductid,
OrganisationProductProjectionState.organisationproductreportingid,
'Wastage' as [ActivityType],
'Unknown' as [ActivityTypeExtra],
StockTransferSummary.Reason as ReasonDescription
from StockTransferSummary
inner join calendar on calendar.Date = StockTransferSummary.CompletedDate
inner join store on store.ExternalStoreCode = StockTransferSummary.ExternalStoreCode
inner join OrganisationProductProjectionState on OrganisationProductProjectionState.ExternalProductId = StockTransferSummary.VmeCode
inner join StoreProjectionState on StoreProjectionState.StoreId = store.StoreId
inner join StoreProductStateProjection storeproduct on storeproduct.StoreReportingId = StoreProjectionState.StoreReportingId and 
					storeproduct.OrganisationProductReportingId = OrganisationProductProjectionState.OrganisationProductReportingId
where StockTransferSummary.Reason = 'WASTAGE'

union all

-- previous year RTC information

select
TranskeyArchiveSummary.date as ActivityDate,
TranskeyArchiveSummary.date as ActivityDateTime, 
calendar.YearWeekNumber,
storeproduct.CurrentStockLevel,
1 as StockTransferQuantity,
0 as IsDelivery,
0 as DeliveryCount,
0 as IsGap,
0 as GapCount,
0 as IsIBTIn,
0 as IBTInCount,
0 as IsIBTOut,
0 as IBTOutCount,
0 as IsOrder,
1 as IsRTC,
1 as RTCCount,
TranskeyArchiveSummary.Price as RTCSalesRetailPrice,
TranskeyArchiveSummary.Price as RTCSales,
TranskeyArchiveSummary.variance as RTCVariance,
1 as IsSale,
1 as SaleCount,
TranskeyArchiveSummary.Price as Sales,
0 as IsStockCheck,
0 as StockCheckCount,
0 as IsStockTake,
0 as StockTakeCount,
0  as IsWastage,
0 as WastageCount,
0 as WastageSales,
0 as [IsStockTransfer],
store.StoreId,
StoreProjectionState.StoreReportingId,
storeproduct.StoreProductId as [ProductId],
storeproduct.StoreProductReportingId as [ProductReportingId],
OrganisationProductProjectionState.organisationproductid,
OrganisationProductProjectionState.organisationproductreportingid,
'RTC' as [ActivityType],
'1 Items Sold' as [ActivityTypeExtra],
TranskeyArchiveSummary.Reason as ReasonDescription
from TranskeyArchiveSummary
inner join calendar on calendar.Date = TranskeyArchiveSummary.date
inner join store on store.ExternalStoreCode = TranskeyArchiveSummary.store
inner join OrganisationProductProjectionState on OrganisationProductProjectionState.ExternalProductId = TranskeyArchiveSummary.VmeCode
inner join StoreProjectionState on StoreProjectionState.StoreId = store.StoreId
inner join StoreProductStateProjection storeproduct on storeproduct.StoreReportingId = StoreProjectionState.StoreReportingId and 
					storeproduct.OrganisationProductReportingId = OrganisationProductProjectionState.OrganisationProductReportingId
where TranskeyArchiveSummary.Reason = 'PK01'