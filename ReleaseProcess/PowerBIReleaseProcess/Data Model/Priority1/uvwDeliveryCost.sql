CREATE OR ALTER VIEW [dbo].[uvwDeliveryCost]
AS
SELECT 
	DeliveryProjectionState.DeliveryReportingId [Delivery Reporting Id], 
    DeliveryProjectionState.ExternalDeliveryCode [Delivery Code],
	DeliveryProjectionState.DeliveryDateTime [Delivery DateTime],
    CONVERT(DATE, DeliveryProjectionState.DeliveryDateTime) [Delivery Date],
    SUM(NumberOfCasesDelivered * CaseCost) Cost,
    SUM(NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price) Retail,
	SUM([OrganisationProductPriceProjectionState].Price) [Product Price],
    SUM(NumberOfCasesDelivered) [Number Of Cases],
	SUM(CaseCost) [Case Cost],
	SUM(CaseSize) [Case Size],
	SUM(CASE WHEN taxrate.[Name] = 'Zero VAT' THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [Zero VAT 0%],
	SUM(CASE WHEN taxrate.[Name] = 'Standard VAT' THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [Standard VAT 20%],
	SUM(CASE WHEN taxrate.[Name] = 'Low Rate VAT' THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [Low Rate VAT 5%],
	SUM(CASE WHEN taxrate.[Name] = 'COVID VAT' THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [COVID VAT 0%],
	StoreProjectionState.StoreReportingId,
	DeliveryProjectionState.SupplierId,
	[order].ExternalOrderId,
	deliveryItemProjectionState.ExternalDeliveryItemId,
	OrganisationProductProjectionState.[Description] [Product Description],
	OrganisationProductProjectionState.Barcode Ean,
	HighestPrioritySupplierSic NSL
FROM deliveryItemProjectionState
INNER JOIN DeliveryProjectionState ON DeliveryProjectionState.DeliveryReportingId = deliveryItemProjectionState.DeliveryReportingId
LEFT OUTER JOIN [order] ON DeliveryProjectionState.OrderId = [order].OrderId 
INNER JOIN StoreProductStateProjection ON StoreProductStateProjection.StoreProductReportingId = deliveryItemProjectionState.StoreProductReportingId
INNER JOIN StoreProjectionState ON StoreProjectionState.StoreReportingId = StoreProductStateProjection.StoreReportingId
INNER JOIN OrganisationProductProjectionState ON OrganisationProductProjectionState.OrganisationProductReportingId = StoreProductStateProjection.OrganisationProductReportingId
INNER JOIN [OrganisationProductPriceProjectionState] ON [OrganisationProductPriceProjectionState].OrganisationProductReportingId = OrganisationProductProjectionState.OrganisationProductReportingId AND OrganisationProductPriceProjectionState.Band = StoreProjectionState.PriceBand
INNER JOIN taxrate ON taxrate.TaxRateId = OrganisationProductProjectionState.TaxRateId
GROUP BY DeliveryProjectionState.DeliveryReportingId, DeliveryProjectionState.ExternalDeliveryCode, DeliveryProjectionState.DeliveryDateTime, StoreProjectionState.StoreReportingId, DeliveryProjectionState.SupplierId, [order].ExternalOrderId, deliveryItemProjectionState.ExternalDeliveryItemId, OrganisationProductProjectionState.[Description], OrganisationProductProjectionState.Barcode, HighestPrioritySupplierSic