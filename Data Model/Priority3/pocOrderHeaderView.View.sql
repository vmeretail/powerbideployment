IF OBJECT_ID('dbo.[pocOrderHeaderView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocOrderHeaderView]; 
GO; 

CREATE VIEW [dbo].[pocOrderHeaderView]
AS

select 
[order].OrderId,
[order].ExternalOrderId as [Order Number],
[order].Status as [Order Status],
[order].StoreId as StoreId,
[order].SupplierId as SupplierId,

CONVERT(DATE, [order].CreatedDateTime) as [Order Date],
CONVERT(DATE, [order].CreatedDateTime) as [Order Completed Date],
CONVERT(DATE, COALESCE([order].ConfirmedDateTime, [order].CreatedDateTime)) as [Order Confirmed Date],
CONVERT(DATE,COALESCE(DeliveredDateTime, PartiallyDeliveredDateTIme, '0001-01-01')) as [Delivery Date],

SUM(ISNULL(orderItem.NumberOfCasesOrdered, 0)) as OrderedQty,
SUM(ISNULL(deliveryitem.numberOfCasesDelivered,0)) as [DeliveredQty],
[Cases Under Over] = SUM(NumberOfCasesDelivered - NumberOfCasesOrdered),
[Cases Under] = SUM(CASE 
					WHEN ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) >= 0 THEN 0 
					ELSE (ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0)) * -1 END),
[Cases Over] = SUM(CASE 
					WHEN ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) <= 0 THEN 0 
					ELSE ISNULL(NumberOfCasesDelivered,0) - ISNULL(NumberOfCasesOrdered,0) END),
[Under Delivered Count] = SUM(CASE WHEN ISNULL(NumberOfCasesDelivered,0) < ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END) ,
[Over Delivered Count] = SUM(CASE WHEN ISNULL(NumberOfCasesDelivered,0) > ISNULL(NumberOfCasesOrdered,0)	 THEN 1 ELSE 0 END) ,
[SLA Met Count] = SUM(CASE WHEN [order].DeliveredDateTime <= NULL AND ISNULL(NumberOfCasesDelivered,0) >=  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END),
count(*) as [Ordered Times Count],
[SLA Missed Count] = SUM(CASE WHEN [order].DeliveredDateTime>= NULL OR ISNULL(NumberOfCasesDelivered,0) <  ISNULL(NumberOfCasesOrdered,0)	     THEN 1 ELSE 0 END),
[OrderSLA] = CASE 
				WHEN CASE WHEN SUM(ISNULL(NumberOfCasesOrdered,0)) = 0 THEN 1 ELSE SUM(ISNULL(NumberOfCasesDelivered,0)) / SUM(NumberOfCasesOrdered) END > 1 THEN 1
				ELSE CASE WHEN SUM(ISNULL(NumberOfCasesOrdered,0)) = 0 THEN 1 ELSE SUM(ISNULL(NumberOfCasesDelivered,0)) / SUM(NumberOfCasesOrdered) END
				END,
StoreProjectionState.StoreReportingId
from [order]
inner join StoreProjectionState on StoreProjectionState.StoreId = [order].StoreId
inner join orderItemProjectionState orderItem on orderItem.OrderId = [order].OrderId
left outer join (
	select delivery.OrderId, StoreProductId, NumberOfCasesDelivered 
	from deliveryItemProjectionState
	inner join delivery on delivery.deliveryId = deliveryItemProjectionState.deliveryid
) deliveryItem on deliveryItem.OrderId = [order].OrderId and orderItem.StoreProductId = deliveryItem.StoreProductId

GROUP BY [order].OrderId,
[order].ExternalOrderId,
[order].[Status],
[order].StoreId,
StoreProjectionState.StoreReportingId,
[order].SupplierId,
[order].CreatedDateTime,
[order].ConfirmedDateTime,
[order].DeliveredDateTime,
COALESCE(DeliveredDateTime, PartiallyDeliveredDateTIme, '0001-01-01')