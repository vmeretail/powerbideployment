IF OBJECT_ID('dbo.[pocOrderDetailsView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocOrderDetailsView]; 
GO; 

CREATE VIEW [dbo].[pocOrderDetailsView]
AS
select

[order].OrderId,
[order].ExternalOrderId as [Order Number],
[order].[Status] as [Order Status],
[order].StoreId,
[order].SupplierId,
CONVERT(DATE, [order].CreatedDateTime) as [Order Date],
CONVERT(DATE, [order].CreatedDateTime) as [Order Completed Date],
CONVERT(DATE, [order].ConfirmedDateTime) as [Order Confirmed Date],
pocDeliveryDetailsView.DeliveryDate as [Delivery Date],
CASE WHEN pocDeliveryDetailsView.DeliveryDate IS NULL THEN 0 ELSE 1 END as IsDelivered,

orderItem.StoreProductId as [ProductId],
storeproduct.StoreProductReportingId as [ProductReportingId],
[Ordered Times Count] = count(*),

SUM(ISNULL(NumberOfCasesOrdered,0)) as [OrderedQty],
SUM(ISNULL(NumberOfCasesDelivered,0)) as [DeliveredQty],
[Cases Under Over] = SUM(NumberOfCasesDelivered - NumberOfCasesOrdered),
[Cases Under] = SUM(CASE 
					WHEN ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) >= 0 THEN 0 
					ELSE (ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0)) * -1 END),

[Cases Over] = SUM(CASE 
					WHEN ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) <= 0 THEN 0 
					ELSE ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) END),

[Under Delivered Count] = SUM(CASE WHEN ISNULL(NumberOfCasesDelivered,0) < ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END) ,
[Over Delivered Count] = SUM(CASE WHEN ISNULL(NumberOfCasesDelivered,0) > ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END) ,
[SLA Met Count] = SUM(CASE WHEN pocDeliveryDetailsView.DeliveryDate <= NULL AND ISNULL(NumberOfCasesDelivered,0) >=  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END),
[SLA Missed Count] = SUM(CASE WHEN pocDeliveryDetailsView.DeliveryDate >= NULL OR ISNULL(NumberOfCasesDelivered,0) <  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END),

[OrderSLA] = CASE WHEN SUM(ISNULL(NumberOfCasesOrdered,0)) = 0 THEN 1 ELSE SUM(ISNULL(NumberOfCasesDelivered,0)) / SUM(NumberOfCasesOrdered) END,
[SIC] = supplierproduct.SIC,
[SupplierPriority] = supplierproduct.Priority,
[SupplierSuspended] = supplierproduct.IsSuspended,
1 AS SICMatched

from orderItemProjectionState orderItem
inner join [order] on orderItem.OrderId = [order].orderId
inner join StoreProductStateProjection storeProduct on orderitem.StoreProductReportingId = storeproduct.StoreProductReportingId
inner join supplierproduct on supplierproduct.Sic = orderItem.Sic and supplierproduct.OrganisationProductId = orderItem.OrganisationProductId and supplierproduct.SupplierId = [order].SupplierId
left outer join pocDeliveryDetailsView on pocDeliveryDetailsView.OrderId = [order].OrderId and pocDeliveryDetailsView.[ProductReportingId] = orderItem.StoreProductReportingId and pocDeliveryDetailsView.SIC = orderItem.SIC

GROUP BY [order].OrderId,
[order].ExternalOrderId,
[order].[Status],
[order].StoreId,
[order].SupplierId,
CONVERT(DATE, [order].CreatedDateTime),
CONVERT(DATE, [order].CreatedDateTime),
CONVERT(DATE, [order].ConfirmedDateTime),
pocDeliveryDetailsView.DeliveryDate,
orderItem.StoreProductId,
storeproduct.StoreProductReportingId,
supplierproduct.SIC,
supplierproduct.Priority,
supplierproduct.IsSuspended