IF OBJECT_ID('dbo.[pocProductsView]', 'V') IS NOT NULL 
  DROP VIEW dbo.[pocProductsView]; 
GO; 

CREATE VIEW [dbo].[pocProductsView]
AS

SELECT storeproduct.StoreProductId as [ProductId],
	   storeproduct.StoreProductReportingId as [ProductReportingId],	
	   organisationproduct.OrganisationProductId,
	   organisationproduct.OrganisationProductReportingId as [OrganisationProductReportingId],
	   store.StoreId,
	   store.StoreReportingId,
	   store.StoreName,

	   priceState.Price as [StandardRetailPriceInc],
	   (ISNULL(priceState.Price,0) / (taxrate.Rate + 1)) as [StandardRetailPriceEx],

	   storeproduct.CurrentMPL as CurrentMPL,
	   storeproduct.PreviousMPL as PreviousMPL,
	   storeproduct.LastMPLChanged as LastMPLChangedDateTime,
	   CONVERT(DATE, storeproduct.LastMPLChanged) as LastMPLChanged,
	   storeproduct.LastDelivery as LastDeliveryDateTime,
	   CONVERT(DATE, storeproduct.LastDelivery) as LastDelivery,
	   storeproduct.LastOrder as LastOrderDateTime,
	   CONVERT(DATE, storeproduct.LastOrder) as LastOrder,
	   storeproduct.LastSale as LastSaleDateTime,
	   CONVERT(DATE, storeproduct.LastSale) as LastSale,
	   storeproduct.OutOfStockSince as OutOfStockSinceDateTime,
	   CONVERT(DATE, storeproduct.OutOfStockSince) as OutOfStockSince,
	   storeproduct.CurrentStockLevel,
	   storeproduct.NumberOfTimesOutOfStock,
	   CONVERT(DATE, storeproduct.LastTimeOutOfStock) as LastTimeOutOfStock,
	   CASE
		WHEN convert(varchar, storeproduct.LastTimeOutOfStock, 5) = '01-01-01' THEN 'None'
		ELSE convert(varchar, storeproduct.LastTimeOutOfStock, 113)
	   END as LastTimeOutOfStockString,
	   storeproduct.LastTimeOutOfStock as LastTimeOutOfStockDateTime,

	   organisationproduct.Description as [ProductDescription],
	   organisationproduct.ExternalProductId,
	   organisationproduct.ItemSize,
	   organisationproduct.ProductHierarchyNodeId,

	   organisationproduct.HighestPrioritySupplierId as SupplierId,
	   organisationproduct.HighestPriorityProductSupplierId as ProductSupplierId,
	   organisationproduct.HighestPrioritySupplierCostPrice as CostPrice,
	   organisationproduct.HighestPrioritySupplierUnitCostPrice as UnitCostPrice,
	   CONVERT(INTEGER, organisationproduct.HighestPrioritySupplierCaseSize) as CaseSize,
	   organisationproduct.HighestPrioritySupplierSic as Sic,
	   organisationproduct.HighestPrioritySupplierPriority as SupplierPriority,

	   organisationproduct.TaxRateId,
	   taxrate.Rate as VatRate,
	   taxrate.Rate + 1 as CalculationVatRate,

	   organisationproduct.Barcode as Ean,

	   -- Margin Values
	   priceState.MarginValue,
	   priceState.MarginPercent as 'Margin%',

	   storeproduct.NumberOfOrdersSinceLastDelivery as [Number Of Orders Since Last Delivery],
	   AverageSalesPerDay as  [Sales Per Day Average],
	   storeproduct.FailedDeliveryCountSinceLastDelivery as [NumberOfFailedDeliveriesSinceLastDelivery],

	   organisationproduct.Description + ' ' + organisationproduct.ExternalProductId + ' ' + organisationproduct.Barcode + ' ' + organisationproduct.HighestPrioritySupplierSic as ProductFilter

FROM StoreProductStateProjection storeproduct
inner join StoreProjectionState store on store.StoreReportingId = storeproduct.StoreReportingId
inner join OrganisationProductProjectionState organisationproduct on organisationproduct.OrganisationProductReportingId = storeproduct.OrganisationProductReportingId
inner join OrganisationProductPriceProjectionState priceState on priceState.OrganisationProductReportingId = organisationproduct.OrganisationProductReportingId and priceState.Band = store.PriceBand
inner join taxrate on taxrate.TaxRateId = organisationproduct.TaxRateId