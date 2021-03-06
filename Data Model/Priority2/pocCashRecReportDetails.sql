IF OBJECT_ID('dbo.pocCashRecReportDetails', 'V') IS NOT NULL 
  DROP VIEW dbo.pocCashRecReportDetails; 
GO; 

CREATE VIEW pocCashRecReportDetails
AS
select 
	ReportDate,
	StoreId,
	CashRecReporting.DepartmentId,
	BasketCount,
	BasketTotal,
	MarginTotal,
	SaleType,
	CASE SaleType
		WHEN 'excludingselecteddepartment' THEN 'Excluding ' + pocHierarchyView.DepartmentName
		WHEN 'includingselecteddepartment' THEN 'Including ' + pocHierarchyView.DepartmentName
		WHEN 'onlyselecteddepartment' THEN 'Only ' + pocHierarchyView.DepartmentName
	END AS FormattedSaleType
from CashRecReporting
inner join pocHierarchyView ON pocHierarchyView.ProductHierarchyId = CashRecReporting.DepartmentId