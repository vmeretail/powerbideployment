IF OBJECT_ID('dbo.pocStoresView', 'V') IS NOT NULL 
  DROP VIEW dbo.pocStoresView; 
GO; 

CREATE VIEW [dbo].pocStoresView
AS
SELECT 
	StoreProjectionState.StoreId,
	ExternalStoreId,
	StoreName + ' (' + ExternalStoreId + ')' as Name,
	StoreStatus as Status,
	PriceBand,
	WastageAndRTCTarget,
	StoreProjectionState.StoreReportingId,
	areamanagerstore.AreaManagerId
FROM StoreProjectionState
LEFT OUTER JOIN areamanagerstore on areamanagerstore.StoreReportingId = StoreProjectionState.StoreReportingId
WHERE StoreStatus = 2