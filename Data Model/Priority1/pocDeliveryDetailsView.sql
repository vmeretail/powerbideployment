IF OBJECT_ID('dbo.pocDeliveryDetailsView', 'V') IS NOT NULL 
  DROP VIEW dbo.pocDeliveryDetailsView; 
GO; 

CREATE VIEW pocDeliveryDetailsView
AS
SELECT
	deliveryItem.StoreProductId as [ProductId],
	storeproduct.StoreProductReportingId as [ProductReportingId],
	delivery.OrderId,
	ExternalOrderId,
	CONVERT(DATE, COALESCE(delivery.DeliveryDateTime, '0001-01-01')) as DeliveryDate,
	SUM(NumberOfCasesDelivered) as NumberOfCasesDelivered,
	organisationproduct.HighestPrioritySupplierSic as SIC
FROM delivery
inner join deliveryItemProjectionState deliveryItem on delivery.DeliveryId = deliveryItem .DeliveryId
inner join StoreProductStateProjection storeproduct on storeproduct.StoreproductReportingId = deliveryItem.StoreProductReportingId
inner join OrganisationProductProjectionState organisationproduct on organisationproduct.OrganisationProductReportingId = storeproduct.OrganisationProductReportingId and organisationproduct.HighestPrioritySupplierSic = deliveryItem.Sic
group by CONVERT(DATE, COALESCE(delivery.DeliveryDateTime, '0001-01-01')),
delivery.OrderId,
ExternalOrderId,
deliveryItem.StoreProductId,
storeproduct.StoreProductReportingId,
organisationproduct.HighestPrioritySupplierSic