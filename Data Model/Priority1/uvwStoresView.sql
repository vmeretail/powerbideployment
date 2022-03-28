CREATE OR ALTER VIEW [dbo].[uvwStoresView]
AS
SELECT 
	StoreProjectionState.StoreId,
	ExternalStoreId,
	StoreName + ' (' + ExternalStoreId + ')' as Name,
	StoreStatus as Status,
	DateRegistered,
	LastDelivery,
	LastOrder,
	LastSale,
	PriceBand,
	WastageAndRTCTarget,
	StoreProjectionState.StoreReportingId,
	areamanagerstore.AreaManagerId
FROM StoreProjectionState
LEFT OUTER JOIN areamanagerstore on areamanagerstore.StoreReportingId = StoreProjectionState.StoreReportingId
WHERE StoreStatus = 2