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
	StoreReportingId
FROM StoreProjectionState
WHERE StoreStatus = 2

