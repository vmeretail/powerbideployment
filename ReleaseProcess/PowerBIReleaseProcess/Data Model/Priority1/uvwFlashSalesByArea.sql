CREATE OR ALTER VIEW [dbo].[uvwFlashSalesByArea]
AS
	SELECT 
		store.StoreId,
		store.[Name] Store,
		producthierarchy.DepartmentId,	
		producthierarchy.SectionId,
		producthierarchy.DepartmentName,
		producthierarchy.SectionName,
		CONVERT(char(36), salestransactioncompleted.AggregateID) AggregateID,
		LineTotalInc,
		CompletedDate
	FROM salestransactioncompleted
	INNER JOIN salestransactionline ON salestransactioncompleted.AggregateId = salestransactionline.AggregateId
	INNER JOIN store ON salestransactioncompleted.StoreId = store.StoreId
	INNER JOIN (
		SELECT DISTINCT 
			DepartmentId,
			SectionId,
			DepartmentName,
			SectionName
		FROM producthierarchy
	) producthierarchy ON producthierarchy.DepartmentId = salestransactionline.departmentId AND producthierarchy.SectionId = salestransactionline.sectionId
	WHERE CompletedDate >= '2022-01-16' AND CompletedDate < CONVERT(date, GETDATE())
	
	UNION ALL

	SELECT 
		store.StoreId,
		store.[Name] Store,
		producthierarchy.DepartmentId,	
		producthierarchy.SectionId,
		producthierarchy.DepartmentName,
		producthierarchy.SectionName,
		NULL,
		SaleLineInc,
		CompletedDate
	FROM StockTransferSummary
	INNER JOIN store ON StockTransferSummary.ExternalStoreCode = store.ExternalStoreCode	
	INNER JOIN (
		SELECT DISTINCT 
			DepartmentId,
			SectionId,
			DepartmentName,
			SectionName,
			SubsectionName,
			SubsectionNumber
		FROM producthierarchy
	) producthierarchy ON producthierarchy.SubsectionName = StockTransferSummary.HierarchyName AND producthierarchy.subsectionNumber = StockTransferSummary.HierarchyNumber
	WHERE Reason = 'SALES'