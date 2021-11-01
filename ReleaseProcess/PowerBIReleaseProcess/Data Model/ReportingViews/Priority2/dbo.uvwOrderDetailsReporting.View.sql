CREATE OR ALTER VIEW [dbo].[uvwOrderDetailsReporting]
AS

select
	--[Product ID]	= oi.StoreProductId,
	--[Store ID] = O.StoreID,
	OI.SIC,
	OI.VmeCode
	--[Case Size] = CaseSize,
	--[Order Qty] = NumberOfCasesOrdered,
	--[Delivered Qty] = NumberOfCasesDelivered,
	--[Cases Under Over] = NumberOfCasesDelivered - NumberOfCasesOrdered,
	--[Under Delivered Count] = CASE WHEN ISNULL(NumberOfCasesDelivered,0) < ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END ,
	--[Over Delivered Count] = CASE WHEN ISNULL(NumberOfCasesDelivered,0) > ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END ,
	--[SLA Met Count] = CASE WHEN ISNULL(d.DeliveryDateTime, GETDATE()) <= NULL AND ISNULL(NumberOfCasesDelivered,0) >=  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END,
	--[SLA Missed Count] = CASE WHEN ISNULL(d.DeliveryDateTime, GETDATE()) >= NULL OR ISNULL(NumberOfCasesDelivered,0) <  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END,
	--[Ordered Times Count] = 1,
	--[Supplier ID] = o.SupplierId,
	--[Order Date] = CONVERT(DATE, o.CreatedDateTime),
	--[Order Time] = CONVERT(TIME, o.CreatedDateTime),
	----[Delivery Date] = CONVERT(DATE, d.DeliveryDateTime),
	----[Delivery Time] = CONVERT(TIME, d.DeliveryDateTime),
	----[Supplier Name] = uvwProductsReporting.[Supplier Name],
	----[Department Id] = uvwProductsReporting.[Department ID],
	----[Department Name] = uvwProductsReporting.[Department Name],
	----[Product Description] = uvwProductsReporting.[Product Description],
	----[Is Mismatched NSL] = CASE 
	----						WHEN LEN(OI.SIC) = 0 THEN '0'
	----						WHEN barcodenslmatch.MostPrimeNSL IS NULL THEN '0'
	----						WHEN ISNULL(sicnslmatch.MostPrimeNSL,0) != 0 THEN '0'
	----						ELSE '1' END,
	----[Most Prime NSL] = barcodenslmatch.MostPrimeNSL,
	--[Order Number]						= o.ExternalOrderId,
	--[Order Status] = o.[Status]
	--[Store Name] = uvwStoresReporting.[Store Name]
	
from dbo.orderItem OI	
--INNER JOIN dbo.[order] o ON o.OrderID = OI.OrderId	
--LEFT JOIN dbo.deliveryItem	DI ON OI.OrderId = DI.OrderId and OI.ExternalOrderItemId = DI.ExternalOrderItemId
--LEFT JOIN dbo.delivery d ON d.OrderId = o.OrderId
--inner join uvwProductsReporting ON uvwProductsReporting.[Product ID] = oi.StoreProductId
--inner join uvwStoresReporting ON uvwStoresReporting.[Store ID] = o.StoreId
