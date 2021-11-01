CREATE OR ALTER VIEW [dbo].[uvwOrderHeaderReporting]
AS

Select 
	--TOP 10 
	[Order ID]							= o.OrderId,
	[Order Created Date] = CONVERT(DATE, o.CreatedDateTime),
	[Order Created Time] = CONVERT(TIME, o.CreatedDateTime),
	[Order Confirmed Date] = CONVERT(DATE, o.ConfirmedDateTime),
	[Order Confirmed Time] = CONVERT(TIME, o.ConfirmedDateTime),
	[Order Generated Date] = CONVERT(DATE, o.GeneratedDateTime),
	[Order Generated Time] = CONVERT(TIME, o.GeneratedDateTime),
	[Order Delivered Date] = CONVERT(DATE, o.DeliveredDateTime),
	[Order Delivered Time] = CONVERT(TIME, o.DeliveredDateTime),
	[Order External Supplier ID]		= o.ExternalSupplierId,
	[Supplier ID]						= o.SupplierID,
	[Order Status]						= o.[Status],
	[Store ID]							= o.StoreId,
	[Store Name]						= s.[Name],
	[Order Number]						= o.ExternalOrderId

from dbo.[order] o	
inner join store s on s.StoreId = o.StoreId