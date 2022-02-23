CREATE OR ALTER VIEW [dbo].[pocStoresView]
AS
SELECT 
	StoreId,
	ExternalStoreId,
	StoreName + ' (' + ExternalStoreId + ')' as Name,
	StoreStatus as Status,
	DateRegistered,
	LastDelivery,
	LastOrder,
	LastSale,
	PriceBand,
	StoreProjectionState.StoreReportingId,
	ISNULL(areamanagerstore.AreaManagerId,0) as AreaManagerId
FROM StoreProjectionState WITH(NOLOCK)
LEFT OUTER join areamanagerstore on areamanagerstore.StoreReportingId = StoreProjectionState.StoreReportingId
WHERE StoreStatus = 2