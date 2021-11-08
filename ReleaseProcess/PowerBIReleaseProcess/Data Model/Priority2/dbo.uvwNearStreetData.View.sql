CREATE OR ALTER VIEW [dbo].[uvwNearStreetData]
AS
SELECT 
	store.StoreId,
	store.Name as StoreName,
	store.ExternalStoreId as StoreNumber,
	storeproduct.StoreProductId,
	OrganisationProductProjectionState.Description as ProductDescription,
	OrganisationProductProjectionState.Barcode,
	organisationproductprice.Price,
	StoreProductState.CurrentStockLevel as Quantity,	
	'GBP' as Currency
FROM storeproduct
inner join OrganisationProductProjectionState on OrganisationProductProjectionState.OrganisationProductId = storeproduct.OrganisationProductId
INNER JOIN store on store.StoreId = storeproduct.StoreId
INNER JOIN storepriceband on store.StoreId = storepriceband.StoreId
INNER JOIN organisationproductprice on organisationproductprice.OrganisationProductId = storeproduct.OrganisationProductId 
									   AND organisationproductprice.Band = storepriceband.Band
INNER JOIN StoreProductStateProjection StoreProductState on StoreProductState.StoreProductId = storeproduct.StoreProductId
where StoreProductState.CurrentStockLevel > 0
AND StoreProductState.LastSale > DATEADD(WEEK, -4, GETDATE())