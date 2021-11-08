CREATE OR ALTER VIEW pocDeliveryDetailsView
AS
SELECT
	deliveryItem.StoreProductId as [ProductId],
	storeproduct.StoreProductReportingId as [ProductReportingId],
	delivery.OrderId,
	ExternalOrderId,
	CONVERT(DATE, COALESCE(delivery.DeliveryDateTime, '0001-01-01')) as DeliveryDate,
	SUM(NumberOfCasesDelivered) as NumberOfCasesDelivered
FROM delivery
inner join deliveryItemProjectionState deliveryItem on delivery.DeliveryId = deliveryItem .DeliveryId
inner join StoreProductStateProjection storeproduct on storeproduct.StoreproductReportingId = deliveryItem.StoreProductReportingId
group by CONVERT(DATE, COALESCE(delivery.DeliveryDateTime, '0001-01-01')),
delivery.OrderId,
ExternalOrderId,
deliveryItem.StoreProductId,
storeproduct.StoreProductReportingId