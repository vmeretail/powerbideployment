CREATE OR ALTER   VIEW [dbo].[pocStockManagementView]
AS

SELECT DISTINCT
[ProductId] = storeproductactivity.StoreProductId,
[ProductReportingId] = storeproductactivity.StoreProductReportingId,
storeproductactivity.ActivityDateTime,
storeproductactivity.ActivityDate,
storeproductactivity.StoreId,
OrganisationProductProjectionState.HighestPrioritySupplierId as SupplierId,
CASE WHEN storeproductactivity.IsRTC = 1 THEN 'REDUCED TO CLEAR' ELSE storeproductactivity.ReasonDescription END as ReasonDescription,
storeproductactivity.StockTransferQuantity,

-- Sales figures
ThisWeekSales = CASE WHEN storeproductactivity.Issale = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, 0, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 1, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,
LastWeekSales = CASE WHEN storeproductactivity.Issale = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -1, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 0, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,
Last2WeekSales = CASE WHEN storeproductactivity.Issale = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -2, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, -1, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,
Last3WeekSales = CASE WHEN storeproductactivity.Issale = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -3, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, -2, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,
Last4WeekSales = CASE WHEN storeproductactivity.Issale = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -4, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, -3, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,

-- RTC Figures
ThisWeekRTCSales = CASE WHEN storeproductactivity.IsRTC = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, 0, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 1, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,
LastWeekRTCSales = CASE WHEN storeproductactivity.IsRTC = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -1, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 0, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
				THEN NumberOfItemsSold ELSE 0 END,

-- Wastage Figures
ThisWeekWastageCount = CASE 
				WHEN storeproductactivity.IsWastage = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, 0, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 1, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND StockTransferQuantity >= 0
						THEN StockTransferQuantity
				WHEN storeproductactivity.IsWastage = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, 0, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 1, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND StockTransferQuantity < 0
				THEN StockTransferQuantity * -1 				
				ELSE 0 END,
LastWeekWastageCount = CASE 
				WHEN storeproductactivity.IsWastage = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -1, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 0, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND StockTransferQuantity >= 0
				THEN StockTransferQuantity 
				WHEN storeproductactivity.IsWastage = 1
						AND ActivityDate 
						BETWEEN DATEADD(wk, -1, DATEADD(DAY, 1-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND DATEADD(wk, 0, DATEADD(DAY, 0-DATEPART(WEEKDAY, GETDATE()), DATEDIFF(dd, 0, GETDATE()))) 
						AND StockTransferQuantity < 0
				THEN StockTransferQuantity * -1 
				ELSE 0 END,
WastageCount = CASE WHEN storeproductactivity.IsWastage = 1 THEN StockTransferQuantity * -1  ELSE 0 END,
RTCCount = CASE WHEN storeproductactivity.IsRTC = 1 THEN NumberOfItemsSold  ELSE 0 END,		
WasteageOrRTC = CASE WHEN storeproductactivity.IsWastage = 1 OR storeproductactivity.IsRTC = 1 THEN 1 ELSE 0 END

FROM storeproductactivity
inner join StoreProductStateProjection on StoreProductStateProjection.StoreProductReportingId = storeproductactivity.StoreProductReportingId
inner join OrganisationProductProjectionState on OrganisationProductProjectionState.OrganisationProductReportingId = StoreProductStateProjection.OrganisationProductReportingId

where (CAST(IsRTC as INT)+ CAST(IsSale as INT)+ CAST(IsWastage as INT)) > 0