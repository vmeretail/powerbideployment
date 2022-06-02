CREATE OR ALTER VIEW [dbo].[uvwDeliveryCost]
AS
SELECT 
	DeliveryProjectionState.DeliveryReportingId [Delivery Reporting Id], 
    DeliveryProjectionState.ExternalDeliveryCode [Delivery Code],
	DeliveryProjectionState.DeliveryDateTime [Delivery DateTime],
    CONVERT(date, DeliveryProjectionState.DeliveryDateTime) [Delivery Date],
    SUM(NumberOfCasesDelivered * CaseCost) Cost,
    SUM(NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price) Retail,
	SUM([OrganisationProductPriceProjectionState].Price) [Product Price],
    SUM(NumberOfCasesDelivered) [Number Of Cases],
	SUM(CaseCost) [Case Cost],
	SUM(CaseSize) [Case Size],
	SUM(CASE WHEN taxrate.[Rate] = 0 THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [VAT 0%],
	SUM(CASE WHEN taxrate.[Rate] = 0.05 THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [VAT 5%],
	SUM(CASE WHEN taxrate.[Rate] = 0.2 THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [VAT 20%],
	SUM(CASE WHEN taxrate.[Rate] = 0.05 AND taxrate.[Name] = 'COVID VAT' THEN NumberOfCasesDelivered * CaseSize * [OrganisationProductPriceProjectionState].Price ELSE 0 END) [COVID VAT 5%],
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